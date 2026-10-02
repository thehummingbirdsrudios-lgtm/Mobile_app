# Operator runbook: businesses and owner accounts

Vepari has no public sign-up. An operator (you, in the Supabase dashboard)
creates each business and its owner; owners then create their own staff in
the app (More → Staff). Project: `vepari` (`zzghblixuxhjxpxzugac`).

## Add a business and its owner
1. **Pick the owner's username.**
   - 3–32 characters: lowercase letters, digits, `.` and `_`.
   - It must start with a letter or digit, for example `rameshbhai`.
   - It must be unique across all businesses.
2. **Create the login.** Go to **Authentication → Users → Add user → Create new user**.
   - Email: `<username>@login.vepari.invalid`. This is not a real address; no email is ever sent.
   - Password: the owner's choice, 8–72 characters. Tell it to them in person.
   - Tick **Auto Confirm User**.
   - Copy the new user's **UID**.
3. **Create the business.** In the **SQL Editor**, run:
   ```sql
   select public.admin_create_tenant(
     'ramesh-jewellers',        -- slug: 3–40 chars, lowercase letters, digits, dashes; unique
     'Ramesh Jewellers',        -- business name shown on bills
     '<UID from step 2>',
     'rameshbhai',              -- the username from step 1
     'Rameshbhai'               -- the owner's display name
   );
   ```
4. **The owner's first sign-in.** The owner logs in with the username and password, then:
   - fills in **More → Business details**: phone, WhatsApp, address, GSTIN, logo;
   - adds staff in **More → Staff**.

## Common requests
| Request | What to do |
|---|---|
| Staff forgot their password | The owner resets it: More → Staff → the person → Reset password |
| Staff phone lost | The owner turns **Access off** for that person. It works on their next request; a password reset alone does not end an open session (KI-015). |
| Owner forgot their password | SQL Editor: `update auth.users set encrypted_password = extensions.crypt('<new password>', extensions.gen_salt('bf')) where email = '<username>@login.vepari.invalid';` Then tell the owner in person. |
| Pause a business | `update public.tenants set status = 'suspended' where slug = '<slug>';` Everyone in it is signed out on their next request. Use `'active'` to restore. |
| Retire old app versions | `update public.platform_settings set min_app_version = '0.2.0';` Older builds then show "Update required". |
| Maintenance window | `update public.platform_settings set maintenance = true;` Business writes pause; reads keep working. Set it back to `false` when done. |

## QA business
"Vepari QA (test)" (slug `vepari-qa`) is used for end-to-end checks.
- Its logins are `qa.owner` and `qa.staff`, and its data is test data only.
- It is isolated from every other business like any tenant.
- When it is no longer needed, suspend it with the "Pause a business" step above.
