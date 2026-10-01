-- Vaat (voice / text / photo remarks), photo enquiries, generated share
-- assets, in-app notifications and the tenant-aware append-only audit log.

create type public.remark_kind as enum ('voice', 'text', 'photo');
create type public.enquiry_status as enum ('open', 'closed');
create type public.share_source as enum ('product', 'new_maal', 'order', 'bill', 'receipt', 'hisaab', 'enquiry');

-- ---------------------------------------------------------------------------
-- Photo enquiries ("Aa design joie che" + photo)
-- ---------------------------------------------------------------------------
create table public.photo_enquiries (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id),
  customer_id uuid,
  status public.enquiry_status not null default 'open',
  photo_path text not null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (tenant_id, id),
  foreign key (tenant_id, customer_id) references public.customers (tenant_id, id),
  check (photo_path like tenant_id::text || '/%')
);
create index photo_enquiries_recent on public.photo_enquiries (tenant_id, created_at desc);
create trigger photo_enquiries_stamp before insert on public.photo_enquiries
  for each row execute function app.stamp_tenant();
create trigger photo_enquiries_touch before update on public.photo_enquiries
  for each row execute function app.touch_row();

-- ---------------------------------------------------------------------------
-- Remarks: exactly one parent. Voice notes are stored as the ORIGINAL
-- recording (no transcription), referenced by storage path.
-- ---------------------------------------------------------------------------
create table public.remarks (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id),
  kind public.remark_kind not null,
  text_body text check (length(btrim(text_body)) between 1 and 2000),
  media_path text,
  duration_ms integer check (duration_ms between 500 and 900000),
  customer_id uuid,
  order_id uuid,
  product_id uuid,
  enquiry_id uuid,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  foreign key (tenant_id, customer_id) references public.customers (tenant_id, id),
  foreign key (tenant_id, order_id) references public.orders (tenant_id, id),
  foreign key (tenant_id, product_id) references public.products (tenant_id, id),
  foreign key (tenant_id, enquiry_id) references public.photo_enquiries (tenant_id, id),
  check (num_nonnulls(customer_id, order_id, product_id, enquiry_id) = 1),
  check (kind <> 'text' or text_body is not null),
  check (kind <> 'voice' or (media_path is not null and duration_ms is not null)),
  check (kind <> 'photo' or media_path is not null),
  check (media_path is null or media_path like tenant_id::text || '/%')
);
create index remarks_by_customer on public.remarks (tenant_id, customer_id, created_at desc) where customer_id is not null;
create index remarks_by_order on public.remarks (tenant_id, order_id, created_at desc) where order_id is not null;
create index remarks_by_product on public.remarks (tenant_id, product_id, created_at desc) where product_id is not null;
create index remarks_by_enquiry on public.remarks (tenant_id, enquiry_id, created_at desc) where enquiry_id is not null;
create trigger remarks_stamp before insert on public.remarks
  for each row execute function app.stamp_tenant();

-- ---------------------------------------------------------------------------
-- Share assets: every externally shared file is deliberately produced and
-- recorded (who, from what) so it can be audited and cleaned up on expiry.
-- ---------------------------------------------------------------------------
create table public.share_assets (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id),
  source public.share_source not null,
  source_id uuid not null,
  storage_path text not null,
  expires_at timestamptz not null default now() + interval '7 days',
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  check (storage_path like tenant_id::text || '/%'),
  check (expires_at > created_at)
);
create index share_assets_expiry on public.share_assets (expires_at);
create trigger share_assets_stamp before insert on public.share_assets
  for each row execute function app.stamp_tenant();

-- ---------------------------------------------------------------------------
-- Notifications (schema now; delivery via FCM in a later increment).
-- Targets are (kind, id) and are re-authorised when opened — never trusted.
-- ---------------------------------------------------------------------------
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id),
  recipient_id uuid not null,
  kind text not null check (kind in ('new_maal', 'order_update', 'bill_ready', 'payment_received', 'new_enquiry')),
  target_kind text check (target_kind in ('product', 'order', 'customer', 'bill', 'enquiry', 'new_maal')),
  target_id uuid,
  args jsonb not null default '{}'::jsonb,
  dedupe_key text not null,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  unique (tenant_id, recipient_id, dedupe_key),
  foreign key (tenant_id, recipient_id) references public.tenant_members (tenant_id, user_id)
);
create index notifications_inbox on public.notifications (tenant_id, recipient_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Audit log: append-only, tenant-scoped, owner-readable. Never stores
-- secrets; owner-only commercial fields are recorded as "changed", not values.
-- ---------------------------------------------------------------------------
create table public.audit_logs (
  id bigint generated always as identity primary key,
  tenant_id uuid not null references public.tenants (id),
  actor_id uuid,
  action text not null check (length(action) <= 60),
  entity text not null check (length(entity) <= 60),
  entity_id uuid,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index audit_logs_recent on public.audit_logs (tenant_id, created_at desc);
create index audit_logs_entity on public.audit_logs (tenant_id, entity, entity_id);
create trigger audit_logs_immutable before update or delete on public.audit_logs
  for each row execute function app.forbid_mutation();

create or replace function app.audit(p_tenant uuid, p_action text, p_entity text, p_entity_id uuid, p_data jsonb default '{}'::jsonb)
returns void
language sql
set search_path = ''
as $$
  insert into public.audit_logs (tenant_id, actor_id, action, entity, entity_id, data)
  values (p_tenant, auth.uid(), p_action, p_entity, p_entity_id, coalesce(p_data, '{}'::jsonb));
$$;

-- Row-change audit. TG_ARGV[0] = 'redact' records only which fields changed.
create or replace function app.audit_row() returns trigger
language plpgsql security definer
set search_path = ''
as $$
declare
  v_new jsonb := case when tg_op = 'DELETE' then null else to_jsonb(new) end;
  v_old jsonb := case when tg_op = 'INSERT' then null else to_jsonb(old) end;
  v_redact boolean := coalesce(tg_argv[0], '') = 'redact';
  v_changes jsonb;
  v_row jsonb := coalesce(v_new, v_old);
  v_entity_id uuid;
begin
  select coalesce(jsonb_object_agg(
           n.key,
           case when v_redact then to_jsonb('changed'::text)
                else jsonb_build_object('from', v_old -> n.key, 'to', n.value) end), '{}'::jsonb)
    into v_changes
    from jsonb_each(coalesce(v_new, '{}'::jsonb)) n
   where n.key not in ('updated_at', 'updated_by', 'created_at', 'created_by', 'tenant_id')
     and (v_old is null or (v_old -> n.key) is distinct from n.value);

  if tg_op = 'UPDATE' and v_changes = '{}'::jsonb then
    return new;
  end if;

  v_entity_id := coalesce(v_row ->> 'id', v_row ->> 'product_id', v_row ->> 'user_id')::uuid;

  perform app.audit((v_row ->> 'tenant_id')::uuid, lower(tg_op), tg_table_name, v_entity_id, v_changes);
  return coalesce(new, old);
end
$$;

create trigger products_audit after insert or update on public.products
  for each row execute function app.audit_row();
create trigger product_private_audit after insert or update on public.product_private
  for each row execute function app.audit_row('redact');
create trigger customers_audit after insert or update on public.customers
  for each row execute function app.audit_row();
create trigger customer_product_rates_audit after insert or update or delete on public.customer_product_rates
  for each row execute function app.audit_row();
create trigger business_profiles_audit after update on public.business_profiles
  for each row execute function app.audit_row();
create trigger tenant_members_audit after insert or update on public.tenant_members
  for each row execute function app.audit_row();
create trigger member_permissions_audit after insert or delete on public.member_permissions
  for each row execute function app.audit_row();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.photo_enquiries enable row level security;
alter table public.remarks enable row level security;
alter table public.share_assets enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

create policy photo_enquiries_rw on public.photo_enquiries for all to authenticated
  using (tenant_id = (select app.current_tenant_id()))
  with check (tenant_id = (select app.current_tenant_id()));

create policy remarks_select on public.remarks for select to authenticated
  using (tenant_id = (select app.current_tenant_id()));
create policy remarks_insert on public.remarks for insert to authenticated
  with check (tenant_id = (select app.current_tenant_id()));
-- Only the author or the owner can archive a remark.
create policy remarks_update on public.remarks for update to authenticated
  using (tenant_id = (select app.current_tenant_id()) and (created_by = auth.uid() or (select app.is_owner())))
  with check (tenant_id = (select app.current_tenant_id()));

create policy share_assets_rw on public.share_assets for all to authenticated
  using (tenant_id = (select app.current_tenant_id()) and created_by = auth.uid())
  with check (tenant_id = (select app.current_tenant_id()));

create policy notifications_own on public.notifications for select to authenticated
  using (tenant_id = (select app.current_tenant_id()) and recipient_id = auth.uid());
create policy notifications_mark_read on public.notifications for update to authenticated
  using (tenant_id = (select app.current_tenant_id()) and recipient_id = auth.uid())
  with check (tenant_id = (select app.current_tenant_id()) and recipient_id = auth.uid());

create policy audit_logs_owner on public.audit_logs for select to authenticated
  using (tenant_id = (select app.current_tenant_id()) and (select app.is_owner()));

revoke all on public.photo_enquiries, public.remarks, public.share_assets, public.notifications,
  public.audit_logs from anon, authenticated;
grant select on public.photo_enquiries, public.remarks, public.share_assets, public.notifications,
  public.audit_logs to authenticated;
grant insert (customer_id, photo_path) on public.photo_enquiries to authenticated;
grant update (status, customer_id) on public.photo_enquiries to authenticated;
grant insert (kind, text_body, media_path, duration_ms, customer_id, order_id, product_id, enquiry_id)
  on public.remarks to authenticated;
grant update (archived_at) on public.remarks to authenticated;
grant insert (source, source_id, storage_path, expires_at) on public.share_assets to authenticated;
grant delete on public.share_assets to authenticated;
grant update (read_at) on public.notifications to authenticated;
