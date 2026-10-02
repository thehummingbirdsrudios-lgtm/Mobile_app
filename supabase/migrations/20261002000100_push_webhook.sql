-- Push webhook, versioned (replaces the manual "Database Webhook" step).
--
-- Every new notification row is handed to the push-dispatch Edge Function
-- through pg_net. pg_net is asynchronous: the request is queued and sent
-- after commit by a background worker, so a slow or failing push never delays
-- or rolls back the business write that created the notification.
--
-- Configuration lives in Supabase Vault, per environment (never in git):
--   vepari_push_url     https://<ref>.supabase.co/functions/v1/push-dispatch
--   vepari_push_secret  random; generated inside the database, never printed
-- Without both secrets the trigger does nothing (local, CI, unconfigured).
--
-- The request body carries the notification id only. push-dispatch looks up
-- the recipients' devices with push_targets(), so no business data (names,
-- amounts) travels in the webhook or lands in pg_net's response log.

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_net') then
    create extension if not exists pg_net with schema extensions;
  end if;
end
$$;

create or replace function app.dispatch_push() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_url text;
  v_secret text;
begin
  select max(s.decrypted_secret) filter (where s.name = 'vepari_push_url'),
         max(s.decrypted_secret) filter (where s.name = 'vepari_push_secret')
    into v_url, v_secret
    from vault.decrypted_secrets s
   where s.name in ('vepari_push_url', 'vepari_push_secret');
  if v_url is null or v_secret is null then
    return null;
  end if;

  begin
    perform net.http_post(
      url := v_url,
      body := jsonb_build_object(
        'type', 'INSERT', 'schema', 'public', 'table', 'notifications',
        'record', jsonb_build_object('id', new.id)),
      headers := jsonb_build_object('Content-Type', 'application/json', 'x-webhook-secret', v_secret),
      timeout_milliseconds := 5000
    );
  exception when others then
    -- The in-app inbox already has the row; a push is best effort.
    raise warning 'push dispatch not queued: %', sqlstate;
  end;
  return null;
end
$$;
revoke all on function app.dispatch_push() from public;

create trigger notifications_push
  after insert on public.notifications
  for each row execute function app.dispatch_push();

-- The Edge Function reads the shared secret with the service role (the
-- platform injects that key into functions; it never reaches the app).
create or replace function public.push_webhook_secret() returns text
language sql stable security definer
set search_path = ''
as $$
  select s.decrypted_secret from vault.decrypted_secrets s where s.name = 'vepari_push_secret'
$$;
revoke all on function public.push_webhook_secret() from public, anon, authenticated;
grant execute on function public.push_webhook_secret() to service_role;

-- push_targets also returns what the notification is about, so tapping the
-- push can open the right screen. Ids only — the target screen re-checks
-- access under RLS when it loads.
drop function public.push_targets(uuid);

create function public.push_targets(p_notification_id uuid)
returns table (token text, platform text, locale text, kind text, args jsonb, target_kind text, target_id uuid)
language sql stable security definer
set search_path = ''
as $$
  select d.token, d.platform, d.locale::text, n.kind, n.args, n.target_kind, n.target_id
    from public.notifications n
    join public.tenant_members m on m.tenant_id = n.tenant_id and m.user_id = n.recipient_id and m.is_active
    join public.tenants t on t.id = n.tenant_id and t.status = 'active'
    join public.device_tokens d on d.tenant_id = n.tenant_id and d.user_id = n.recipient_id
   where n.id = p_notification_id and n.read_at is null;
$$;
revoke all on function public.push_targets(uuid) from public, anon, authenticated;
grant execute on function public.push_targets(uuid) to service_role;
