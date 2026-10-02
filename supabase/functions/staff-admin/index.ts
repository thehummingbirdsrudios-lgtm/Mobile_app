// Edge Function entry point: wires the real Supabase clients into handler.ts.
//
// Secrets (Supabase dashboard / `supabase secrets set`):
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY  (provided by the platform)
//   LOGIN_DOMAIN  must equal the app's LOGIN_DOMAIN (env/<env>.json)
// Deploy: supabase functions deploy staff-admin   (JWT verification stays ON)
import { createClient } from "npm:@supabase/supabase-js@2.58.0";

import { type Deps, handle } from "./handler.ts";

const env = (name: string): string => {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`missing env ${name}`);
  return value;
};

const url = env("SUPABASE_URL");
const anonKey = env("SUPABASE_ANON_KEY");
const loginDomain = env("LOGIN_DOMAIN");
const noSession = { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false };
const admin = createClient(url, env("SUPABASE_SERVICE_ROLE_KEY"), { auth: noSession });

const deps: Deps = {
  loginDomain,

  async caller(authorization) {
    const asCaller = createClient(url, anonKey, {
      auth: noSession,
      global: { headers: { Authorization: authorization } },
    });
    const { data, error } = await asCaller.rpc("current_session");
    if (error || !data || typeof data !== "object") return null;
    const session = data as { user_id?: unknown; role?: unknown };
    if (typeof session.user_id !== "string") return null;
    return { userId: session.user_id, isOwner: session.role === "owner" };
  },

  async createAuthUser(email, password) {
    const { data, error } = await admin.auth.admin.createUser({ email, password, email_confirm: true });
    if (error || !data.user) {
      const code = (error as { code?: string } | null)?.code ?? "";
      if (code === "email_exists" || code === "user_already_exists") return { error: "exists" };
      if (code === "weak_password" || error?.status === 422) return { error: "rejected" };
      return { error: "failed" };
    }
    return { id: data.user.id };
  },

  async deleteAuthUser(userId) {
    const { error } = await admin.auth.admin.deleteUser(userId);
    if (error) throw new Error("delete_failed");
  },

  async setPassword(userId, password) {
    const { error } = await admin.auth.admin.updateUserById(userId, { password });
    if (!error) return "ok";
    const code = (error as { code?: string }).code ?? "";
    if (code === "user_not_found" || error.status === 404) return "not_found";
    if (code === "weak_password" || error.status === 422) return "rejected";
    return "failed";
  },

  async rpc(fn, args) {
    const { data, error } = await admin.rpc(fn, args);
    if (!error) return { ok: true, data };
    // app.fail() raises P0001 with the stable code as the message; anything
    // else (a constraint race, an outage) is reported by SQLSTATE.
    if (error.code === "P0001") return { ok: false, code: error.message };
    if (error.code === "23505") return { ok: false, code: "username_taken" };
    return { ok: false, code: "server_error" };
  },

  log(event, fields) {
    console.log(JSON.stringify({ fn: "staff-admin", event, ...fields }));
  },
};

Deno.serve((req) => handle(req, deps));
