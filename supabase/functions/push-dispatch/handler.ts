// push-dispatch: sends a push for each new in-app notification.
//
// Wiring: an AFTER INSERT trigger on public.notifications (migration
// 20261002000100_push_webhook.sql) POSTs `{type, table, record: {id}}` here
// through pg_net with the header `x-webhook-secret`. This handler is pure
// (I/O injected) and unit-tested; index.ts wires Supabase and FCM.
//
// Status words match the app (app_*.arb status*).
//
// Privacy rules
//  - Devices come from push_targets(): only the recipient's own devices, and
//    only while they are an active member of an active business.
//  - The push text is safe on a lock screen: no amounts, no rates. Tapping
//    opens the app, which re-reads and re-authorises the target.
//  - The data payload carries ids only: the notification, its kind and what
//    it is about (so a tap can open that screen). No names or amounts.

export type Target = {
  token: string;
  platform: string;
  locale: string;
  kind: string;
  args: Record<string, unknown>;
  target_kind?: string | null;
  target_id?: string | null;
};
export type Push = { token: string; title: string; body: string; data: Record<string, string> };
export type SendResult = "ok" | "invalid_token" | "failed";

export interface Deps {
  webhookSecret: string;
  targets(notificationId: string): Promise<Target[]>;
  /** null when FCM is not configured for this project. */
  send: ((push: Push) => Promise<SendResult>) | null;
  forget(tokens: string[]): Promise<void>;
  log(event: string, fields: Record<string, string | number | boolean | null>): void;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_BODY_BYTES = 16 * 1024;

type Locale = "gu" | "hi" | "en";

const TEXT: Record<Locale, Record<string, string>> = {
  en: {
    newMaal: "New Maal",
    newOrder: "New order",
    order: "Order",
    payment: "Payment received",
    confirmed: "Confirmed",
    processing: "In process",
    ready: "Ready",
    completed: "Completed",
    cancelled: "Cancelled",
  },
  gu: {
    newMaal: "નવો માલ",
    newOrder: "નવો ઓર્ડર",
    order: "ઓર્ડર",
    payment: "પેમેન્ટ મળ્યું",
    confirmed: "કન્ફર્મ",
    processing: "બની રહ્યો છે",
    ready: "તૈયાર",
    completed: "પૂરો",
    cancelled: "રદ",
  },
  hi: {
    newMaal: "नया माल",
    newOrder: "नया ऑर्डर",
    order: "ऑर्डर",
    payment: "पेमेंट मिला",
    confirmed: "कन्फ़र्म",
    processing: "बन रहा है",
    ready: "तैयार",
    completed: "पूरा",
    cancelled: "रद्द",
  },
};

const str = (
  v: unknown,
  max = 80,
): string => (typeof v === "string" ? v.slice(0, max) : typeof v === "number" ? `${v}` : "");

/** Lock-screen-safe title and body for one notification. Null for unknown kinds. */
export function pushText(
  kind: string,
  args: Record<string, unknown>,
  locale: string,
): { title: string; body: string } | null {
  const t = TEXT[(locale as Locale) in TEXT ? (locale as Locale) : "gu"];
  switch (kind) {
    case "new_maal":
      return { title: t.newMaal, body: [str(args.design_no), str(args.name)].filter(Boolean).join(" · ") };
    case "order_update": {
      const no = str(args.order_no);
      if (args.event === "created") {
        return { title: t.newOrder, body: [`#${no}`, str(args.customer_name)].filter(Boolean).join(" · ") };
      }
      const status = str(args.status);
      return { title: `${t.order} #${no}`, body: t[status] ?? status };
    }
    case "payment_received":
      // The amount stays in the app (Hisaab permission), never on a lock screen.
      return { title: t.payment, body: str(args.customer_name) };
    default:
      return null;
  }
}

function constantTimeEqual(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

const reply = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

export async function handle(req: Request, deps: Deps): Promise<Response> {
  if (req.method !== "POST") return reply(405, { error: "method_not_allowed" });
  const secret = req.headers.get("x-webhook-secret") ?? "";
  if (deps.webhookSecret.length < 16 || !constantTimeEqual(secret, deps.webhookSecret)) {
    return reply(401, { error: "not_authenticated" });
  }

  const text = await req.text();
  if (new TextEncoder().encode(text).length > MAX_BODY_BYTES) return reply(400, { error: "invalid_request" });
  let id = "";
  try {
    const payload = JSON.parse(text);
    if (payload?.type !== "INSERT" || payload?.table !== "notifications") {
      return reply(400, { error: "invalid_request" });
    }
    id = typeof payload.record?.id === "string" ? payload.record.id : "";
  } catch {
    return reply(400, { error: "invalid_request" });
  }
  if (!UUID.test(id)) return reply(400, { error: "invalid_request" });

  if (!deps.send) {
    deps.log("push.skipped", { reason: "fcm_not_configured" });
    return reply(200, { sent: 0, skipped: "not_configured" });
  }

  let targets: Target[];
  try {
    targets = await deps.targets(id);
  } catch {
    deps.log("push.targets_failed", {});
    return reply(500, { error: "server_error" });
  }
  let sent = 0;
  let failed = 0;
  const invalid: string[] = [];
  for (const target of targets) {
    const text = pushText(target.kind, target.args ?? {}, target.locale);
    if (!text) continue;
    const data: Record<string, string> = { notification_id: id, kind: target.kind };
    if (target.target_kind && target.target_id && UUID.test(target.target_id)) {
      data.target_kind = target.target_kind;
      data.target_id = target.target_id;
    }
    const result = await deps.send({ token: target.token, ...text, data }).catch((): SendResult => "failed");
    if (result === "ok") sent++;
    else if (result === "invalid_token") invalid.push(target.token);
    else failed++;
  }
  if (invalid.length) await deps.forget(invalid);
  // Counts only: never tokens, names or text.
  deps.log("push.done", { devices: targets.length, sent, invalid: invalid.length, failed });
  return reply(200, { sent, invalid: invalid.length, failed });
}
