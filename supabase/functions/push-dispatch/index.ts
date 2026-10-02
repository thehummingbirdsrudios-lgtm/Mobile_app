// Edge Function entry point for push-dispatch.
//
// Secrets (Supabase dashboard / `supabase secrets set`):
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY  (provided by the platform)
//   PUSH_WEBHOOK_SECRET    random, ≥ 16 chars; sent by the Database Webhook
//                          as the `x-webhook-secret` header
//   FCM_SERVICE_ACCOUNT    optional: the Firebase service-account JSON. When
//                          absent, notifications stay in-app only.
// Deploy: supabase functions deploy push-dispatch --no-verify-jwt
//   (the webhook authenticates with PUSH_WEBHOOK_SECRET, not a user JWT)
// Webhook: Database → Webhooks → INSERT on public.notifications → this URL.
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

const account = Deno.env.get("FCM_SERVICE_ACCOUNT");
const sender = account ? new FcmSender(JSON.parse(account) as ServiceAccount) : null;

const deps: Deps = {
  webhookSecret: env("PUSH_WEBHOOK_SECRET"),
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

Deno.serve((req) => handle(req, deps));
