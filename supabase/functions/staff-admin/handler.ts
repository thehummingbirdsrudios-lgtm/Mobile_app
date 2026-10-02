// staff-admin: owner-only staff account management (create, reset password).
//
// Account creation needs the Auth admin API (service role), which must never
// reach the app. This handler is pure: every I/O is injected through [Deps],
// so the rules below are unit-tested without a network (handler_test.ts) and
// index.ts only wires the real Supabase clients.
//
// Security rules
//  - The caller is resolved from THEIR JWT via current_session(): an active
//    owner of an active business, or the request is refused.
//  - The tenant is never read from the request. The database derives it from
//    the caller (staff_admin_* functions), so a forged body cannot reach
//    another business.
//  - Passwords and tokens are never logged or echoed back.
//  - A half-created account is rolled back (auth user deleted) if the
//    membership cannot be written.

export const GRANTABLE = [
  "catalogue.manage",
  "rates.manage",
  "customers.manage",
  "orders.create",
  "orders.manage",
  "payments.record",
  "hisaab.view",
  "hisaab.adjust",
  "bills.issue",
  "reports.view",
] as const;

export type Permission = (typeof GRANTABLE)[number];

export type Caller = { userId: string; isOwner: boolean };

export type DbResult = { ok: true; data?: unknown } | { ok: false; code: string };

export type CreateUserResult = { id: string } | { error: "exists" | "rejected" | "failed" };

export interface Deps {
  loginDomain: string;
  /** current_session() as the caller; null for an invalid token or inactive membership. */
  caller(authorization: string): Promise<Caller | null>;
  createAuthUser(email: string, password: string): Promise<CreateUserResult>;
  deleteAuthUser(userId: string): Promise<void>;
  setPassword(userId: string, password: string): Promise<"ok" | "rejected" | "not_found" | "failed">;
  /** Service-role RPC. `code` is the app.fail() code (e.g. username_taken). */
  rpc(fn: string, args: Record<string, unknown>): Promise<DbResult>;
  log(event: string, fields: Record<string, string | number | boolean | null>): void;
}

const MAX_BODY_BYTES = 4096;
const USERNAME = /^[a-z0-9][a-z0-9._]{2,31}$/;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
// deno-lint-ignore no-control-regex
const CONTROL = /[\u0000-\u001f\u007f]/;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

const fail = (status: number, error: string, field?: string) => json(status, field ? { error, field } : { error });

type Invalid = { field: string };

function passwordIssue(password: unknown, username?: string): Invalid | null {
  if (typeof password !== "string") return { field: "password" };
  const bytes = new TextEncoder().encode(password).length;
  // bcrypt (GoTrue) uses only the first 72 bytes: longer would silently truncate.
  if (bytes < 8 || bytes > 72 || password.trim().length === 0) return { field: "password" };
  if (username && password.toLowerCase() === username) return { field: "password" };
  return null;
}

type NewStaff = { username: string; displayName: string; password: string; permissions: Permission[] };

function parseCreate(body: Record<string, unknown>): NewStaff | Invalid {
  const username = typeof body.username === "string" ? body.username.trim().toLowerCase() : "";
  if (!USERNAME.test(username)) return { field: "username" };

  const displayName = typeof body.display_name === "string" ? body.display_name.trim() : "";
  if (displayName.length < 1 || displayName.length > 80 || CONTROL.test(displayName)) {
    return { field: "display_name" };
  }

  const issue = passwordIssue(body.password, username);
  if (issue) return issue;

  const raw = body.permissions ?? [];
  if (!Array.isArray(raw) || raw.length > GRANTABLE.length) return { field: "permissions" };
  const permissions = new Set<Permission>();
  for (const p of raw) {
    if (typeof p !== "string" || !(GRANTABLE as readonly string[]).includes(p)) return { field: "permissions" };
    permissions.add(p as Permission);
  }
  return { username, displayName, password: body.password as string, permissions: [...permissions] };
}

async function readBody(req: Request): Promise<Record<string, unknown> | null> {
  const declared = Number(req.headers.get("content-length") ?? "0");
  if (declared > MAX_BODY_BYTES) return null;
  const text = await req.text();
  if (new TextEncoder().encode(text).length > MAX_BODY_BYTES) return null;
  try {
    const value = JSON.parse(text);
    return value !== null && typeof value === "object" && !Array.isArray(value) ? value : null;
  } catch {
    return null;
  }
}

const statusFor = (code: string) =>
  code === "permission_denied" ? 403 : code === "member_not_found" ? 404 : code === "username_taken" ? 409 : 500;

async function createStaff(deps: Deps, caller: Caller, staff: NewStaff): Promise<Response> {
  const created = await deps.createAuthUser(`${staff.username}@${deps.loginDomain}`, staff.password);
  if ("error" in created) {
    deps.log("staff.create.auth_failed", { actor: caller.userId, reason: created.error });
    return created.error === "exists"
      ? fail(409, "username_taken")
      : created.error === "rejected"
      ? fail(400, "invalid_request", "password")
      : fail(500, "server_error");
  }

  const result = await deps.rpc("staff_admin_create", {
    p_actor: caller.userId,
    p_user_id: created.id,
    p_username: staff.username,
    p_display_name: staff.displayName,
    p_permissions: staff.permissions,
  });
  if (!result.ok) {
    // Never leave a login without a membership behind.
    await deps.deleteAuthUser(created.id).catch(() =>
      deps.log("staff.create.rollback_failed", { actor: caller.userId, user: created.id })
    );
    deps.log("staff.create.db_failed", { actor: caller.userId, code: result.code });
    return result.code === "invalid_request" ? fail(400, "invalid_request") : fail(statusFor(result.code), result.code);
  }

  deps.log("staff.created", { actor: caller.userId, user: created.id, permissions: staff.permissions.length });
  return json(200, { user_id: created.id });
}

async function resetPassword(deps: Deps, caller: Caller, body: Record<string, unknown>): Promise<Response> {
  const userId = typeof body.user_id === "string" ? body.user_id : "";
  if (!UUID.test(userId)) return fail(400, "invalid_request", "user_id");
  const issue = passwordIssue(body.password);
  if (issue) return fail(400, "invalid_request", issue.field);

  // Authorise BEFORE touching the account.
  const target = await deps.rpc("staff_admin_check_target", { p_actor: caller.userId, p_user_id: userId });
  if (!target.ok) {
    deps.log("staff.reset.denied", { actor: caller.userId, code: target.code });
    return fail(statusFor(target.code), target.code);
  }

  const outcome = await deps.setPassword(userId, body.password as string);
  if (outcome !== "ok") {
    deps.log("staff.reset.auth_failed", { actor: caller.userId, user: userId, reason: outcome });
    return outcome === "rejected"
      ? fail(400, "invalid_request", "password")
      : outcome === "not_found"
      ? fail(404, "member_not_found")
      : fail(500, "server_error");
  }

  const audit = await deps.rpc("staff_admin_record_password_reset", { p_actor: caller.userId, p_user_id: userId });
  // The password HAS changed; report that truthfully even if the audit write failed.
  if (!audit.ok) deps.log("staff.reset.audit_failed", { actor: caller.userId, user: userId, code: audit.code });
  deps.log("staff.password_reset", { actor: caller.userId, user: userId });
  return json(200, { user_id: userId });
}

export async function handle(req: Request, deps: Deps): Promise<Response> {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
  if (req.method !== "POST") return fail(405, "method_not_allowed");

  const authorization = req.headers.get("authorization") ?? "";
  if (!/^Bearer \S+$/.test(authorization)) return fail(401, "not_authenticated");

  const body = await readBody(req);
  if (!body) return fail(400, "invalid_request");

  let caller: Caller | null;
  try {
    caller = await deps.caller(authorization);
  } catch {
    deps.log("staff.caller_lookup_failed", {});
    return fail(500, "server_error");
  }
  if (!caller) return fail(401, "not_authenticated");
  if (!caller.isOwner) {
    deps.log("staff.denied", { actor: caller.userId, action: String(body.action ?? "") });
    return fail(403, "permission_denied");
  }

  try {
    switch (body.action) {
      case "create_staff": {
        const parsed = parseCreate(body);
        if ("field" in parsed) return fail(400, "invalid_request", parsed.field);
        return await createStaff(deps, caller, parsed);
      }
      case "reset_password":
        return await resetPassword(deps, caller, body);
      default:
        return fail(400, "invalid_request", "action");
    }
  } catch (e) {
    deps.log("staff.unexpected", { actor: caller.userId, error: e instanceof Error ? e.name : "unknown" });
    return fail(500, "server_error");
  }
}
