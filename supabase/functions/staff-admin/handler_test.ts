// Unit tests for the staff-admin rules (no network): deno test supabase/functions
import { type Caller, type CreateUserResult, type DbResult, type Deps, handle } from "./handler.ts";

function assertEquals(actual: unknown, expected: unknown, message = "") {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${message}\nexpected: ${e}\n  actual: ${a}`);
}

const OWNER: Caller = { userId: "11111111-1111-4111-8111-111111111111", isOwner: true };
const STAFF: Caller = { userId: "22222222-2222-4222-8222-222222222222", isOwner: false };
const TARGET = "33333333-3333-4333-8333-333333333333";
const NEW_ID = "44444444-4444-4444-8444-444444444444";
const PASSWORD = "Moti-Haar-2026";

type Call = { fn: string; args: Record<string, unknown> };

class Fake implements Deps {
  loginDomain = "login.vepari.invalid";
  who: Caller | null = OWNER;
  createResult: CreateUserResult = { id: NEW_ID };
  passwordResult: "ok" | "rejected" | "not_found" | "failed" = "ok";
  rpcResults: Record<string, DbResult> = {};
  created: { email: string; password: string }[] = [];
  deleted: string[] = [];
  passwords: { userId: string; password: string }[] = [];
  calls: Call[] = [];
  logs: string[] = [];
  seenAuthorization = "";

  caller(authorization: string) {
    this.seenAuthorization = authorization;
    return Promise.resolve(this.who);
  }
  createAuthUser(email: string, password: string) {
    this.created.push({ email, password });
    return Promise.resolve(this.createResult);
  }
  deleteAuthUser(userId: string) {
    this.deleted.push(userId);
    return Promise.resolve();
  }
  setPassword(userId: string, password: string) {
    this.passwords.push({ userId, password });
    return Promise.resolve(this.passwordResult);
  }
  rpc(fn: string, args: Record<string, unknown>) {
    this.calls.push({ fn, args });
    return Promise.resolve(this.rpcResults[fn] ?? { ok: true });
  }
  log(event: string, fields: Record<string, unknown>) {
    this.logs.push(JSON.stringify({ event, ...fields }));
  }
}

function request(body: unknown, { auth = "Bearer token-abc", method = "POST" } = {}) {
  return new Request("https://fn.example/staff-admin", {
    method,
    headers: { authorization: auth, "content-type": "application/json" },
    body: method === "POST" ? (typeof body === "string" ? body : JSON.stringify(body)) : undefined,
  });
}

async function send(deps: Fake, body: unknown, init?: { auth?: string; method?: string }) {
  const res = await handle(request(body, init), deps);
  const text = await res.text();
  return { status: res.status, body: text ? JSON.parse(text) : null };
}

const createBody = (over: Record<string, unknown> = {}) => ({
  action: "create_staff",
  username: "Kiran",
  display_name: "  Kiranbhai ",
  password: PASSWORD,
  permissions: ["orders.create", "orders.create", "hisaab.view"],
  ...over,
});

Deno.test("owner creates staff: auth user, then membership derived from the caller", async () => {
  const deps = new Fake();
  const res = await send(deps, createBody());
  assertEquals(res, { status: 200, body: { user_id: NEW_ID } });
  assertEquals(deps.seenAuthorization, "Bearer token-abc");
  assertEquals(deps.created, [{ email: "kiran@login.vepari.invalid", password: PASSWORD }]);
  assertEquals(deps.calls, [{
    fn: "staff_admin_create",
    args: {
      p_actor: OWNER.userId,
      p_user_id: NEW_ID,
      p_username: "kiran",
      p_display_name: "Kiranbhai",
      p_permissions: ["orders.create", "hisaab.view"],
    },
  }]);
});

Deno.test("a tenant id in the body is ignored — the database derives it", async () => {
  const deps = new Fake();
  await send(deps, createBody({ tenant_id: "99999999-9999-4999-8999-999999999999" }));
  assertEquals(Object.keys(deps.calls[0].args).includes("p_tenant_id"), false);
  assertEquals(JSON.stringify(deps.calls).includes("9999"), false);
});

Deno.test("staff and invalid sessions are refused before any account change", async () => {
  const staff = new Fake();
  staff.who = STAFF;
  assertEquals(await send(staff, createBody()), { status: 403, body: { error: "permission_denied" } });

  const signedOut = new Fake();
  signedOut.who = null;
  assertEquals(await send(signedOut, createBody()), { status: 401, body: { error: "not_authenticated" } });

  const noHeader = new Fake();
  assertEquals(await send(noHeader, createBody(), { auth: "" }), { status: 401, body: { error: "not_authenticated" } });

  for (const deps of [staff, signedOut, noHeader]) {
    assertEquals(deps.created.length + deps.passwords.length + deps.calls.length, 0);
  }
});

Deno.test("input validation names the field and creates nothing", async () => {
  const cases: [Record<string, unknown>, string][] = [
    [{ username: "ab" }, "username"],
    [{ username: "has space" }, "username"],
    [{ username: "Ünïcode" }, "username"],
    [{ display_name: "   " }, "display_name"],
    [{ display_name: "x".repeat(81) }, "display_name"],
    [{ display_name: "bad\u0007name" }, "display_name"],
    [{ password: "short" }, "password"],
    [{ password: "ઘ".repeat(25) }, "password"], // 75 UTF-8 bytes > bcrypt's 72
    [{ password: " ".repeat(10) }, "password"],
    [{ password: 12345678 }, "password"],
    [{ username: "kiranbhai", password: "KiranBhai" }, "password"], // equals username
    [{ permissions: ["owner"] }, "permissions"],
    [{ permissions: "orders.create" }, "permissions"],
    [{ action: "delete_everything" }, "action"],
  ];
  for (const [over, field] of cases) {
    const deps = new Fake();
    const res = await send(deps, createBody(over));
    assertEquals(res, { status: 400, body: { error: "invalid_request", field } }, JSON.stringify(over));
    assertEquals(deps.created.length, 0, JSON.stringify(over));
  }
});

Deno.test("malformed and oversized bodies are rejected", async () => {
  const deps = new Fake();
  assertEquals((await send(deps, "{not json")).status, 400);
  assertEquals((await send(deps, "[1,2]")).status, 400);
  assertEquals((await send(deps, createBody({ display_name: "x".repeat(5000) }))).status, 400);
  assertEquals((await send(deps, null, { method: "GET" })).status, 405);
  const preflight = await handle(new Request("https://fn.example/staff-admin", { method: "OPTIONS" }), deps);
  assertEquals(preflight.status, 204);
  assertEquals(deps.created.length, 0);
});

Deno.test("a taken username maps to 409 without touching the database", async () => {
  const deps = new Fake();
  deps.createResult = { error: "exists" };
  assertEquals(await send(deps, createBody()), { status: 409, body: { error: "username_taken" } });
  assertEquals(deps.calls.length, 0);
});

Deno.test("a membership failure rolls the new login back", async () => {
  for (
    const [code, status] of [["username_taken", 409], ["permission_denied", 403], ["server_error", 500]] as const
  ) {
    const deps = new Fake();
    deps.rpcResults.staff_admin_create = { ok: false, code };
    const res = await send(deps, createBody());
    assertEquals(res, { status, body: { error: code } });
    assertEquals(deps.deleted, [NEW_ID], code);
  }
});

Deno.test("reset password: authorised first, then changed, then audited", async () => {
  const deps = new Fake();
  const res = await send(deps, { action: "reset_password", user_id: TARGET, password: PASSWORD });
  assertEquals(res, { status: 200, body: { user_id: TARGET } });
  assertEquals(deps.calls.map((c) => c.fn), ["staff_admin_check_target", "staff_admin_record_password_reset"]);
  assertEquals(deps.calls[0].args, { p_actor: OWNER.userId, p_user_id: TARGET });
  assertEquals(deps.passwords, [{ userId: TARGET, password: PASSWORD }]);
});

Deno.test("reset password for someone outside the business changes nothing", async () => {
  const deps = new Fake();
  deps.rpcResults.staff_admin_check_target = { ok: false, code: "member_not_found" };
  const res = await send(deps, { action: "reset_password", user_id: TARGET, password: PASSWORD });
  assertEquals(res, { status: 404, body: { error: "member_not_found" } });
  assertEquals(deps.passwords.length, 0);

  const bad = new Fake();
  assertEquals(
    await send(bad, { action: "reset_password", user_id: "not-a-uuid", password: PASSWORD }),
    { status: 400, body: { error: "invalid_request", field: "user_id" } },
  );
  assertEquals(bad.calls.length, 0);
});

Deno.test("a reset that Auth accepted is reported even if the audit write fails", async () => {
  const deps = new Fake();
  deps.rpcResults.staff_admin_record_password_reset = { ok: false, code: "server_error" };
  const res = await send(deps, { action: "reset_password", user_id: TARGET, password: PASSWORD });
  assertEquals(res.status, 200);
  assertEquals(deps.logs.some((l) => l.includes("staff.reset.audit_failed")), true);
});

Deno.test("logs never contain passwords or tokens", async () => {
  const deps = new Fake();
  await send(deps, createBody());
  await send(deps, { action: "reset_password", user_id: TARGET, password: PASSWORD });
  deps.rpcResults.staff_admin_create = { ok: false, code: "server_error" };
  await send(deps, createBody());
  const all = deps.logs.join("\n");
  assertEquals(all.includes(PASSWORD), false);
  assertEquals(all.includes("token-abc"), false);
  assertEquals(deps.logs.length > 0, true);
});

Deno.test("responses are JSON and never cached", async () => {
  const res = await handle(request(createBody()), new Fake());
  assertEquals(res.headers.get("content-type"), "application/json");
  assertEquals(res.headers.get("cache-control"), "no-store");
});
