// Unit tests for push-dispatch (no network): deno test supabase/functions
import { FcmSender, type ServiceAccount, signedAssertion } from "./fcm.ts";
import { type Deps, handle, type Push, pushText, type SendResult, type Target } from "./handler.ts";

function assertEquals(actual: unknown, expected: unknown, message = "") {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(`${message}\nexpected: ${e}\n  actual: ${a}`);
}

const SECRET = "webhook-secret-0123456789";
const ID = "55555555-5555-4555-8555-555555555555";

class Fake implements Deps {
  webhookSecret = SECRET;
  rows: Target[] = [];
  results: Record<string, SendResult> = {};
  sent: Push[] = [];
  forgotten: string[][] = [];
  logs: string[] = [];
  targetCalls = 0;
  send: ((push: Push) => Promise<SendResult>) | null = (push) => {
    this.sent.push(push);
    return Promise.resolve(this.results[push.token] ?? "ok");
  };
  targets(_id: string) {
    this.targetCalls++;
    return Promise.resolve(this.rows);
  }
  forget(tokens: string[]) {
    this.forgotten.push(tokens);
    return Promise.resolve();
  }
  log(event: string, fields: Record<string, unknown>) {
    this.logs.push(JSON.stringify({ event, ...fields }));
  }
}

const webhook = (record: unknown, secret = SECRET, type = "INSERT") =>
  new Request("https://fn.example/push-dispatch", {
    method: "POST",
    headers: { "x-webhook-secret": secret, "content-type": "application/json" },
    body: JSON.stringify({ type, table: "notifications", schema: "public", record, old_record: null }),
  });

const target = (token: string, kind: string, args: Record<string, unknown>, locale = "gu"): Target => ({
  token,
  platform: "android",
  locale,
  kind,
  args,
});

Deno.test("rejects calls without the webhook secret", async () => {
  const deps = new Fake();
  assertEquals((await handle(webhook({ id: ID }, "wrong-secret-0123456789"), deps)).status, 401);
  assertEquals((await handle(webhook({ id: ID }, ""), deps)).status, 401);
  const weak = new Fake();
  weak.webhookSecret = "short";
  assertEquals((await handle(webhook({ id: ID }, "short"), weak)).status, 401, "a weak secret is never accepted");
  assertEquals(deps.targetCalls + weak.targetCalls, 0);
});

Deno.test("rejects anything that is not a notification insert", async () => {
  const deps = new Fake();
  assertEquals((await handle(webhook({ id: ID }, SECRET, "UPDATE"), deps)).status, 400);
  assertEquals((await handle(webhook({ id: "x" }), deps)).status, 400);
  const bad = new Request("https://fn.example/push-dispatch", {
    method: "POST",
    headers: { "x-webhook-secret": SECRET },
    body: "{oops",
  });
  assertEquals((await handle(bad, deps)).status, 400);
  assertEquals(deps.targetCalls, 0);
});

Deno.test("without FCM configured, nothing is sent and the call succeeds", async () => {
  const deps = new Fake();
  deps.send = null;
  const res = await handle(webhook({ id: ID }), deps);
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { sent: 0, skipped: "not_configured" });
});

Deno.test("sends one push per device with lock-screen-safe text and minimal data", async () => {
  const deps = new Fake();
  deps.rows = [
    target("tok-a", "payment_received", { customer_name: "Rajeshbhai", amount_paise: 250000, payment_no: 7 }, "en"),
    target("tok-b", "new_maal", { design_no: "1024", name: "Kundan Set" }, "gu"),
  ];
  const res = await handle(webhook({ id: ID }), deps);
  assertEquals(await res.json(), { sent: 2, invalid: 0, failed: 0 });
  assertEquals(deps.sent[0], {
    token: "tok-a",
    title: "Payment received",
    body: "Rajeshbhai",
    data: { notification_id: ID, kind: "payment_received" },
  });
  assertEquals(JSON.stringify(deps.sent).includes("2500"), false, "no amount on the lock screen");
  assertEquals(deps.sent[1].title, "નવો માલ");
  assertEquals(deps.sent[1].body, "1024 · Kundan Set");
});

Deno.test("tokens FCM rejects are forgotten; failures are counted, not fatal", async () => {
  const deps = new Fake();
  deps.rows = [target("dead", "new_maal", { design_no: "1" }), target("flaky", "new_maal", { design_no: "1" })];
  deps.results = { dead: "invalid_token", flaky: "failed" };
  const res = await handle(webhook({ id: ID }), deps);
  assertEquals(await res.json(), { sent: 0, invalid: 1, failed: 1 });
  assertEquals(deps.forgotten, [["dead"]]);
  assertEquals(deps.logs.join().includes("dead"), false, "tokens are never logged");
});

Deno.test("no devices (e.g. stopped staff) means nothing is sent", async () => {
  const deps = new Fake();
  const res = await handle(webhook({ id: ID }), deps);
  assertEquals(await res.json(), { sent: 0, invalid: 0, failed: 0 });
});

Deno.test("push text in three languages; unknown kinds are skipped", () => {
  assertEquals(pushText("order_update", { event: "created", order_no: 1045, customer_name: "Sureshbhai" }, "hi"), {
    title: "नया ऑर्डर",
    body: "#1045 · Sureshbhai",
  });
  assertEquals(pushText("order_update", { event: "status", order_no: 1045, status: "ready" }, "en"), {
    title: "Order #1045",
    body: "Ready",
  });
  assertEquals(pushText("order_update", { event: "status", order_no: 9, status: "completed" }, "gu")?.body, "પૂરો");
  assertEquals(pushText("new_maal", { design_no: "X" }, "fr")?.title, "નવો માલ", "unknown locale → Gujarati");
  assertEquals(pushText("something_new", {}, "en"), null);
});

// --- FCM sender ------------------------------------------------------------

async function testAccount(): Promise<{ account: ServiceAccount; publicKey: CryptoKey }> {
  const pair = await crypto.subtle.generateKey(
    { name: "RSASSA-PKCS1-v1_5", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256" },
    true,
    ["sign", "verify"],
  );
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  const pem = `-----BEGIN PRIVATE KEY-----\n${btoa(String.fromCharCode(...pkcs8))}\n-----END PRIVATE KEY-----\n`;
  return {
    account: { project_id: "vepari-test", client_email: "push@vepari-test.iam.gserviceaccount.com", private_key: pem },
    publicKey: pair.publicKey,
  };
}

const fromB64url = (s: string) =>
  Uint8Array.from(
    atob(s.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(s.length / 4) * 4, "=")),
    (c) => c.charCodeAt(0),
  );

Deno.test("the OAuth assertion is a valid RS256 JWT for the FCM scope", async () => {
  const { account, publicKey } = await testAccount();
  const jwt = await signedAssertion(account, 1_700_000_000);
  const [h, c, s] = jwt.split(".");
  const ok = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    publicKey,
    fromB64url(s),
    new TextEncoder().encode(`${h}.${c}`),
  );
  assertEquals(ok, true);
  const claims = JSON.parse(new TextDecoder().decode(fromB64url(c)));
  assertEquals(claims, {
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: 1_700_000_000,
    exp: 1_700_003_600,
  });
});

Deno.test("sender: token reused until near expiry; errors mapped", async () => {
  const { account } = await testAccount();
  const calls: { url: string; init: RequestInit }[] = [];
  let fcmStatus = 200;
  let fcmBody = "{}";
  let now = 1_700_000_000_000;
  const fetcher = (url: string, init: RequestInit) => {
    calls.push({ url, init });
    if (url.includes("oauth2")) {
      return Promise.resolve(new Response(JSON.stringify({ access_token: `at-${calls.length}`, expires_in: 3600 })));
    }
    return Promise.resolve(new Response(fcmBody, { status: fcmStatus }));
  };
  const sender = new FcmSender(account, fetcher, () => now);
  const push: Push = { token: "tok", title: "T", body: "B", data: { kind: "new_maal" } };

  assertEquals(await sender.send(push), "ok");
  assertEquals(await sender.send(push), "ok");
  assertEquals(calls.filter((c) => c.url.includes("oauth2")).length, 1, "token cached");
  const fcmCall = calls.find((c) => c.url.includes("fcm.googleapis.com"))!;
  assertEquals(fcmCall.url, "https://fcm.googleapis.com/v1/projects/vepari-test/messages:send");
  assertEquals((fcmCall.init.headers as Record<string, string>).Authorization, "Bearer at-1");
  assertEquals(JSON.parse(fcmCall.init.body as string).message.token, "tok");

  now += 3600_000; // expired → new token
  await sender.send(push);
  assertEquals(calls.filter((c) => c.url.includes("oauth2")).length, 2);

  fcmStatus = 404;
  assertEquals(await sender.send(push), "invalid_token");
  fcmStatus = 400;
  fcmBody = '{"error":{"details":[{"errorCode":"UNREGISTERED"}]}}';
  assertEquals(await sender.send(push), "invalid_token");
  fcmStatus = 503;
  fcmBody = "unavailable";
  assertEquals(await sender.send(push), "failed");
});
