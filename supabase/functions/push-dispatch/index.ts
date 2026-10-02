// Edge Function entry point for push-dispatch.
//
// Secrets (Supabase dashboard / `supabase secrets set`):
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY  (provided by the platform)
//   FCM_SERVICE_ACCOUNT    optional: the Firebase service-account JSON. When
//                          absent, notifications stay in-app only.
//   PUSH_WEBHOOK_SECRET    optional override. By default the shared secret is
//                          read from Vault (`vepari_push_secret`) through the
//                          service-role-only RPC push_webhook_secret(), so it
//                          is generated in the database and never handled.
// Deploy: supabase functions deploy push-dispatch --no-verify-jwt
//   (the trigger authenticates with the shared secret, not a user JWT)
// Trigger: migration 20261002000100_push_webhook.sql; configure Vault
//   `vepari_push_url` and `vepari_push_secret` (README → Deploying).
import { createClient } from "npm:@supabase/supabase-js@2.58.0";

import { FcmSender, type ServiceAccount } from "./fcm.ts";
import { type Deps, handle, type Target } from "./handler.ts";

const env = (name: string): string => {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`missing env ${name}`);
  return value;
};

const admin = createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
  auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
});

// A malformed secret (e.g. a partial paste) must not take the function down:
// pushes are skipped and the problem is logged (never the value itself).
function fcmSender(raw: string | undefined): FcmSender | null {
  if (!raw) return null;
  try {
    const account = JSON.parse(raw) as Partial<ServiceAccount>;
    if (account.project_id && account.client_email && account.private_key) {
      return new FcmSender(account as ServiceAccount);
    }
  } catch {
    // fall through
  }
  console.log(JSON.stringify({ fn: "push-dispatch", event: "fcm.config_invalid" }));
  return null;
}

const sender = fcmSender(Deno.env.get("FCM_SERVICE_ACCOUNT"));

// Resolved once per instance; a failed lookup is retried on the next call.
let webhookSecret: string | null = Deno.env.get("PUSH_WEBHOOK_SECRET") || null;
async function resolveSecret(): Promise<string> {
  if (webhookSecret) return webhookSecret;
  const { data, error } = await admin.rpc("push_webhook_secret");
  if (error || typeof data !== "string") return "";
  webhookSecret = data;
  return data;
}

const deps: Omit<Deps, "webhookSecret"> = {
  async targets(id) {
    const { data, error } = await admin.rpc("push_targets", { p_notification_id: id });
    if (error) throw new Error("targets_failed");
    return (data ?? []) as Target[];
  },
  send: sender ? sender.send : null,
  async forget(tokens) {
    await admin.rpc("forget_device_tokens", { p_tokens: tokens });
  },
  log(event, fields) {
    console.log(JSON.stringify({ fn: "push-dispatch", event, ...fields }));
  },
};

// An empty secret fails closed: handle() rejects every call with 401.
Deno.serve(async (req) => handle(req, { ...deps, webhookSecret: await resolveSecret() }));
