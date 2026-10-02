// Firebase Cloud Messaging (HTTP v1) sender with a service-account OAuth
// token. fetch and the clock are injected so the signing and error mapping
// are tested without a network.
import type { Push, SendResult } from "./handler.ts";

export type ServiceAccount = { project_id: string; client_email: string; private_key: string; token_uri?: string };

type Fetch = (input: string, init: RequestInit) => Promise<Response>;

const SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const DEFAULT_TOKEN_URI = "https://oauth2.googleapis.com/token";

const b64url = (bytes: Uint8Array) =>
  btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const b64urlJson = (value: unknown) => b64url(new TextEncoder().encode(JSON.stringify(value)));

async function importKey(pem: string): Promise<CryptoKey> {
  const body = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey("pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, [
    "sign",
  ]);
}

/** Signed RS256 JWT asking Google for an FCM access token. */
export async function signedAssertion(account: ServiceAccount, nowSeconds: number): Promise<string> {
  const header = b64urlJson({ alg: "RS256", typ: "JWT" });
  const claims = b64urlJson({
    iss: account.client_email,
    scope: SCOPE,
    aud: account.token_uri ?? DEFAULT_TOKEN_URI,
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  });
  const input = `${header}.${claims}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    await importKey(account.private_key),
    new TextEncoder().encode(input),
  );
  return `${input}.${b64url(new Uint8Array(signature))}`;
}

export class FcmSender {
  constructor(
    private readonly account: ServiceAccount,
    private readonly fetcher: Fetch = fetch,
    private readonly now: () => number = () => Date.now(),
  ) {}

  private token: { value: string; expiresAt: number } | null = null;

  private async accessToken(): Promise<string> {
    if (this.token && this.token.expiresAt - 60_000 > this.now()) return this.token.value;
    const assertion = await signedAssertion(this.account, Math.floor(this.now() / 1000));
    const res = await this.fetcher(this.account.token_uri ?? DEFAULT_TOKEN_URI, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }).toString(),
    });
    if (!res.ok) throw new Error(`oauth_${res.status}`);
    const body = await res.json() as { access_token?: string; expires_in?: number };
    if (!body.access_token) throw new Error("oauth_no_token");
    this.token = { value: body.access_token, expiresAt: this.now() + (body.expires_in ?? 3600) * 1000 };
    return body.access_token;
  }

  send = async (push: Push): Promise<SendResult> => {
    const res = await this.fetcher(
      `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(this.account.project_id)}/messages:send`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${await this.accessToken()}` },
        body: JSON.stringify({
          message: {
            token: push.token,
            notification: { title: push.title, body: push.body },
            data: push.data,
            android: { priority: "high", notification: { channel_id: "vepari_updates" } },
          },
        }),
      },
    );
    if (res.ok) return "ok";
    const detail = await res.text().catch(() => "");
    // The device uninstalled the app or the token rotated: stop using it.
    if (res.status === 404 || detail.includes("UNREGISTERED") || detail.includes("registration token is not a valid")) {
      return "invalid_token";
    }
    return "failed";
  };
}

/**
 * The FCM sender for the FCM_SERVICE_ACCOUNT secret, or null when push is
 * not configured. A malformed secret (e.g. a partial paste) must not take the
 * function down: it is reported through [onInvalid] (never the value) and
 * push is skipped, so in-app notifications are unaffected.
 */
export function senderFromSecret(raw: string | undefined, onInvalid: () => void, fetcher?: Fetch): FcmSender | null {
  if (!raw) return null;
  try {
    const account = JSON.parse(raw) as Partial<ServiceAccount>;
    if (account.project_id && account.client_email && account.private_key) {
      return new FcmSender(account as ServiceAccount, fetcher);
    }
  } catch {
    // fall through
  }
  onInvalid();
  return null;
}
