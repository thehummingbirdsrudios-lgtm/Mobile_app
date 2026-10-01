# Authentication and sessions

## Login identity
- Users type a **username** (e.g. `rajesh`).
- Supabase Auth requires an email-shaped identifier, so the app derives one:
  `rajesh@login.vepari.invalid` (`Username.loginIdentifier`).
- The `.invalid` TLD is reserved (RFC 2606), so no email can ever be sent
  there. Email confirmation is not used.
- The domain is configurable (`LOGIN_DOMAIN`) and must match the provisioning
  function.

## Accounts
- There is no public signup. Disable "Allow new users to sign up" in the
  Supabase project.
- Owners and staff are created by a service-role Edge Function. This is the
  next auth increment. It:
  1. calls `auth.admin.createUser`;
  2. calls `admin_add_member` (or `admin_create_tenant` for a new business).
- Passwords are hashed by Supabase Auth (bcrypt) and never stored by Vepari.

## Session
- The JWT access token is short-lived and refreshed by the Supabase SDK.
- It is persisted only in the platform keystore (`SecureSessionStorage` →
  flutter_secure_storage).
- Android backup and device transfer of app data are disabled, so a session
  cannot be restored onto another device.
- On launch, the app calls `current_session()` before showing anything.
  A `null` result (disabled or suspended) means immediate local sign-out.
- Logout is local scope. It clears the persisted session, then the tenant
  cache, then shows login.
- Revocation: membership is checked server-side on every request (see
  tenant-security.md).

## Errors
Login failures show one message ("Username or password is wrong."). The
message does not reveal whether the username exists.

## Project settings checklist (hosted Supabase)
- [ ] Disable signups
- [ ] JWT expiry ≤ 1 h
- [ ] Refresh-token rotation on
- [ ] Auth rate limits reviewed
- [ ] Leaked-password protection on
- [ ] Minimum password length ≥ 8
- [ ] Owner MFA when product requirements allow
