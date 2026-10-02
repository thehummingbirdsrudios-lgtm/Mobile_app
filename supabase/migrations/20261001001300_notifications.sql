-- Notifications: in-app inbox + device tokens for push (FCM).
--
-- Rows are written by triggers inside the same transaction as the business
-- event, so a notification exists only for something that committed.
-- Recipients are active members of the SAME business who may see the
-- subject (permission-checked here), never the person who acted.
-- `args` carry only what those recipients may already see in the app.

-- ---------------------------------------------------------------------------
-- Device tokens (one row per app install; a token follows the device's
-- current login — signing in elsewhere moves it, so a business never keeps
-- pushing to a phone that now belongs to someone else).
-- ---------------------------------------------------------------------------
create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id),
  user_id uuid not null,
  token text not null unique check (length(token) between 20 and 4096),
  platform text not null check (platform in ('android', 'ios', 'web')),
  locale public.app_locale not null default 'gu',
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, user_id) references public.tenant_members (tenant_id, user_id) on delete cascade
);
create index device_tokens_by_member on public.device_tokens (tenant_id, user_id);

alter table public.device_tokens enable row level security;
create policy device_tokens_own on public.device_tokens for select to authenticated
  using (tenant_id = (select app.current_tenant_id()) and user_id = auth.uid());
revoke all on public.device_tokens from anon, authenticated;
grant select on public.device_tokens to authenticated;

create or replace function public.register_device_token(p_token text, p_platform text, p_locale public.app_locale)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_tenant();
begin
  if p_token is null or length(p_token) not between 20 and 4096 or p_platform not in ('android', 'ios', 'web') then
    perform app.fail('invalid_request');
  end if;
  insert into public.device_tokens as d (tenant_id, user_id, token, platform, locale)
  values (v_tenant, auth.uid(), p_token, p_platform, coalesce(p_locale, 'gu'))
  on conflict (token) do update
    set tenant_id = excluded.tenant_id, user_id = excluded.user_id, platform = excluded.platform,
        locale = excluded.locale, last_seen_at = now();
  -- A member has a handful of devices at most; keep the 10 most recent.
  delete from public.device_tokens d
   where d.tenant_id = v_tenant and d.user_id = auth.uid()
     and d.id not in (select k.id from public.device_tokens k
                       where k.tenant_id = v_tenant and k.user_id = auth.uid()
                       order by k.last_seen_at desc limit 10);
end
$$;

-- Sign-out: this device stops receiving this member's notifications.
create or replace function public.unregister_device_token(p_token text) returns void
language sql security definer
set search_path = ''
as $$
  delete from public.device_tokens where token = p_token and user_id = auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- Fan-out
-- ---------------------------------------------------------------------------
create index notifications_unread on public.notifications (tenant_id, recipient_id) where read_at is null;
-- The inbox pages by (created_at, id): index both so no sort is needed.
drop index public.notifications_inbox;
create index notifications_inbox on public.notifications (tenant_id, recipient_id, created_at desc, id desc);

-- Inserts one notification per recipient: active members of p_tenant except
-- the actor; everyone when p_everyone, otherwise the owner, p_also, and
-- holders of p_permission.
create or replace function app.notify_members(
  p_tenant uuid, p_everyone boolean, p_permission public.app_permission, p_also uuid,
  p_kind text, p_target_kind text, p_target_id uuid, p_args jsonb, p_dedupe text
) returns void
language sql security definer
set search_path = ''
as $$
  insert into public.notifications (tenant_id, recipient_id, kind, target_kind, target_id, args, dedupe_key)
  select p_tenant, m.user_id, p_kind, p_target_kind, p_target_id, coalesce(p_args, '{}'::jsonb), p_dedupe
    from public.tenant_members m
    join public.tenants t on t.id = m.tenant_id and t.status = 'active'
   where m.tenant_id = p_tenant
     and m.is_active
     and m.user_id is distinct from auth.uid()
     and (p_everyone
          or m.role = 'owner'
          or m.user_id = p_also
          or exists (select 1 from public.member_permissions mp
                      where mp.tenant_id = m.tenant_id and mp.user_id = m.user_id and mp.permission = p_permission))
  on conflict (tenant_id, recipient_id, dedupe_key) do nothing;
$$;

create or replace function app.notify_new_product() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  if new.status = 'active' then
    perform app.notify_members(new.tenant_id, true, null, null, 'new_maal', 'product', new.id,
      jsonb_build_object('design_no', new.design_no, 'name', new.name), 'product:' || new.id);
  end if;
  return null;
end
$$;

create or replace function app.notify_order() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_customer text;
begin
  select c.name into v_customer from public.customers c where c.tenant_id = new.tenant_id and c.id = new.customer_id;
  if tg_op = 'INSERT' then
    -- New order: the owner and whoever manages orders.
    perform app.notify_members(new.tenant_id, false, 'orders.manage', null, 'order_update', 'order', new.id,
      jsonb_build_object('event', 'created', 'order_no', new.order_no, 'customer_name', v_customer),
      'order:' || new.id || ':created');
  elsif new.status is distinct from old.status then
    -- Status change: the owner and the person who took the order.
    perform app.notify_members(new.tenant_id, false, null, new.created_by, 'order_update', 'order', new.id,
      jsonb_build_object('event', 'status', 'order_no', new.order_no, 'customer_name', v_customer,
                         'status', new.status),
      'order:' || new.id || ':' || new.status);
  end if;
  return null;
end
$$;

create or replace function app.notify_payment() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_customer text;
begin
  select c.name into v_customer from public.customers c where c.tenant_id = new.tenant_id and c.id = new.customer_id;
  -- Amounts are Hisaab: only the owner and members who may view Hisaab.
  perform app.notify_members(new.tenant_id, false, 'hisaab.view', null, 'payment_received', 'customer',
    new.customer_id,
    jsonb_build_object('payment_no', new.payment_no, 'amount_paise', new.amount_paise, 'customer_name', v_customer),
    'payment:' || new.id);
  return null;
end
$$;

create trigger products_notify after insert on public.products
  for each row execute function app.notify_new_product();
create trigger orders_notify after insert or update of status on public.orders
  for each row execute function app.notify_order();
create trigger payments_notify after insert on public.payments
  for each row execute function app.notify_payment();

-- ---------------------------------------------------------------------------
-- Inbox (SECURITY INVOKER: RLS limits every read to the caller's own rows)
-- ---------------------------------------------------------------------------
create or replace function public.notification_page(
  p_before_at timestamptz default null, p_before_id uuid default null, p_limit integer default 30
) returns table (
  id uuid, kind text, target_kind text, target_id uuid, args jsonb, read_at timestamptz, created_at timestamptz
)
language sql stable security invoker
set search_path = ''
as $$
  select n.id, n.kind, n.target_kind, n.target_id, n.args, n.read_at, n.created_at
    from public.notifications n
   where n.tenant_id = (select app.current_tenant_id())
     and n.recipient_id = auth.uid()
     and (p_before_at is null or (n.created_at, n.id) < (p_before_at, p_before_id))
   order by n.created_at desc, n.id desc
   limit least(greatest(coalesce(p_limit, 30), 1), 100);
$$;

-- Capped: the badge shows "99+" beyond that.
create or replace function public.unread_notification_count() returns integer
language sql stable security invoker
set search_path = ''
as $$
  select count(*)::integer from (
    select 1 from public.notifications n
     where n.tenant_id = (select app.current_tenant_id()) and n.recipient_id = auth.uid() and n.read_at is null
     limit 100) unread;
$$;

-- Marks the given notifications (or all) read; returns how many changed.
create or replace function public.mark_notifications_read(p_ids uuid[] default null) returns integer
language plpgsql security invoker
set search_path = ''
as $$
declare
  v_count integer;
begin
  update public.notifications n set read_at = now()
   where n.tenant_id = (select app.current_tenant_id()) and n.recipient_id = auth.uid() and n.read_at is null
     and (p_ids is null or n.id = any (p_ids));
  get diagnostics v_count = row_count;
  return v_count;
end
$$;

-- ---------------------------------------------------------------------------
-- Push delivery (service role only, used by the push-dispatch Edge Function)
-- ---------------------------------------------------------------------------
-- Devices to push one notification to — empty unless the recipient is still
-- an active member of an active business.
create or replace function public.push_targets(p_notification_id uuid)
returns table (token text, platform text, locale text, kind text, args jsonb)
language sql stable security definer
set search_path = ''
as $$
  select d.token, d.platform, d.locale::text, n.kind, n.args
    from public.notifications n
    join public.tenant_members m on m.tenant_id = n.tenant_id and m.user_id = n.recipient_id and m.is_active
    join public.tenants t on t.id = n.tenant_id and t.status = 'active'
    join public.device_tokens d on d.tenant_id = n.tenant_id and d.user_id = n.recipient_id
   where n.id = p_notification_id and n.read_at is null;
$$;

-- Drops tokens FCM reported as no longer valid.
create or replace function public.forget_device_tokens(p_tokens text[]) returns void
language sql security definer
set search_path = ''
as $$
  delete from public.device_tokens where token = any (p_tokens);
$$;

revoke all on function
  app.notify_members(uuid, boolean, public.app_permission, uuid, text, text, uuid, jsonb, text),
  app.notify_new_product(), app.notify_order(), app.notify_payment()
  from public;

revoke all on function
  public.register_device_token(text, text, public.app_locale),
  public.unregister_device_token(text),
  public.notification_page(timestamptz, uuid, integer),
  public.unread_notification_count(),
  public.mark_notifications_read(uuid[]),
  public.push_targets(uuid),
  public.forget_device_tokens(text[])
  from public, anon, authenticated;

grant execute on function
  public.register_device_token(text, text, public.app_locale),
  public.unregister_device_token(text),
  public.notification_page(timestamptz, uuid, integer),
  public.unread_notification_count(),
  public.mark_notifications_read(uuid[])
  to authenticated;

grant execute on function
  public.push_targets(uuid),
  public.forget_device_tokens(text[])
  to service_role;
