-- Foundation: extensions, private `app` schema, enums, tenancy, identity,
-- permissions and the security helpers every RLS policy relies on.
--
-- Conventions (see docs/architecture/data-model.md):
--   * every tenant-owned row carries tenant_id and UNIQUE (tenant_id, id) so
--     children reference parents with composite FKs — cross-tenant links are
--     impossible at the constraint level, even from SECURITY DEFINER code.
--   * money = bigint paise; quantity = integer pieces; weight = integer mg.
--   * timestamps are timestamptz (UTC); business dates use the tenant timezone.
--   * the client NEVER supplies tenant_id: it defaults from the session and RLS
--     WITH CHECK rejects any other value.

create extension if not exists pgcrypto with schema extensions;
create extension if not exists pg_trgm with schema extensions;

create schema if not exists app;
revoke all on schema app from public;
grant usage on schema app to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type public.member_role as enum ('owner', 'staff');

-- Grantable staff permissions. Owner-only abilities (staff management,
-- settings, cost/supplier data, audit log, export) are deliberately NOT
-- grantable and are checked with app.is_owner().
create type public.app_permission as enum (
  'catalogue.manage',
  'rates.manage',
  'customers.manage',
  'orders.create',
  'orders.manage',
  'payments.record',
  'hisaab.view',
  'hisaab.adjust',
  'bills.issue',
  'reports.view'
);

create type public.tenant_status as enum ('active', 'suspended');
create type public.app_locale as enum ('gu', 'hi', 'en');

-- ---------------------------------------------------------------------------
-- Generic triggers
-- ---------------------------------------------------------------------------
create or replace function app.touch_row() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  new.updated_by := coalesce(auth.uid(), new.updated_by);
  return new;
end
$$;

-- ---------------------------------------------------------------------------
-- Tenancy & identity
-- ---------------------------------------------------------------------------
create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{2,39}$'),
  status public.tenant_status not null default 'active',
  created_at timestamptz not null default now()
);

-- One profile row per auth user. Username is the human login handle; the
-- auth identifier is derived from it (see docs/security/auth.md).
create table public.app_users (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null check (username ~ '^[a-z0-9][a-z0-9._]{2,31}$'),
  display_name text not null check (length(btrim(display_name)) between 1 and 80),
  created_at timestamptz not null default now()
);
create unique index app_users_username_key on public.app_users (lower(username));

-- A user belongs to exactly one tenant (UNIQUE user_id). A future multi-
-- business user would relax this deliberately, not accidentally.
create table public.tenant_members (
  tenant_id uuid not null references public.tenants (id),
  user_id uuid not null unique references public.app_users (id),
  role public.member_role not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid,
  primary key (tenant_id, user_id)
);

create table public.member_permissions (
  tenant_id uuid not null,
  user_id uuid not null,
  permission public.app_permission not null,
  granted_at timestamptz not null default now(),
  granted_by uuid,
  primary key (tenant_id, user_id, permission),
  foreign key (tenant_id, user_id) references public.tenant_members (tenant_id, user_id) on delete cascade
);

-- ---------------------------------------------------------------------------
-- Security helpers. SECURITY DEFINER so they can read membership without
-- recursing through RLS; STABLE so policies can cache them per statement.
-- They read identity ONLY from the verified JWT (auth.uid()).
-- ---------------------------------------------------------------------------
create or replace function app.current_tenant_id() returns uuid
language sql stable security definer
set search_path = ''
as $$
  select m.tenant_id
  from public.tenant_members m
  join public.tenants t on t.id = m.tenant_id
  where m.user_id = auth.uid()
    and m.is_active
    and t.status = 'active'
$$;

create or replace function app.is_owner() returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce((
    select m.role = 'owner'
    from public.tenant_members m
    join public.tenants t on t.id = m.tenant_id
    where m.user_id = auth.uid() and m.is_active and t.status = 'active'
  ), false)
$$;

create or replace function app.has_permission(p public.app_permission) returns boolean
language sql stable security definer
set search_path = ''
as $$
  select coalesce((
    select m.role = 'owner'
        or exists (
          select 1 from public.member_permissions mp
          where mp.tenant_id = m.tenant_id
            and mp.user_id = m.user_id
            and mp.permission = p
        )
    from public.tenant_members m
    join public.tenants t on t.id = m.tenant_id
    where m.user_id = auth.uid() and m.is_active and t.status = 'active'
  ), false)
$$;

-- Raise stable, machine-readable error codes. The client maps `message` to a
-- localized, human sentence; details never contain other tenants' data.
create or replace function app.fail(code text, detail jsonb default null) returns void
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = 'P0001', message = code, detail = coalesce(detail::text, '');
end
$$;

create or replace function app.require_tenant() returns uuid
language plpgsql stable
set search_path = ''
as $$
declare
  v_tenant uuid := app.current_tenant_id();
begin
  if v_tenant is null then
    perform app.fail('not_authenticated');
  end if;
  return v_tenant;
end
$$;

create or replace function app.require_permission(p public.app_permission) returns uuid
language plpgsql stable
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_tenant();
begin
  if not app.has_permission(p) then
    perform app.fail('permission_denied');
  end if;
  return v_tenant;
end
$$;

create or replace function app.require_owner() returns uuid
language plpgsql stable
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_tenant();
begin
  if not app.is_owner() then
    perform app.fail('permission_denied');
  end if;
  return v_tenant;
end
$$;

revoke all on all functions in schema app from public;
grant execute on function
  app.current_tenant_id(), app.is_owner(), app.has_permission(public.app_permission)
  to authenticated;

-- ---------------------------------------------------------------------------
-- Business profile (tenant branding & bill details) and counters
-- ---------------------------------------------------------------------------
create table public.business_profiles (
  tenant_id uuid primary key references public.tenants (id),
  business_name text not null check (length(btrim(business_name)) between 1 and 120),
  phone text check (phone ~ '^\+?[0-9]{10,15}$'),
  whatsapp_phone text check (whatsapp_phone ~ '^\+?[0-9]{10,15}$'),
  address text check (length(address) <= 400),
  gstin text check (gstin ~ '^[0-9A-Z]{15}$'),
  bill_footer text check (length(bill_footer) <= 400),
  logo_path text,
  watermark_enabled boolean not null default true,
  default_locale public.app_locale not null default 'gu',
  timezone text not null default 'Asia/Kolkata',
  updated_at timestamptz not null default now(),
  updated_by uuid,
  check (logo_path is null or logo_path like tenant_id::text || '/%')
);
create trigger business_profiles_touch before update on public.business_profiles
  for each row execute function app.touch_row();

create table public.tenant_counters (
  tenant_id uuid not null references public.tenants (id),
  counter text not null check (counter in ('order', 'payment', 'bill')),
  next_value bigint not null default 1 check (next_value > 0),
  primary key (tenant_id, counter)
);

-- Per-tenant gapless-ish human numbers (Order #1045). The UPDATE row lock
-- serialises concurrent callers within one tenant only.
create or replace function app.next_number(p_tenant uuid, p_counter text) returns bigint
language plpgsql
set search_path = ''
as $$
declare
  v_value bigint;
begin
  insert into public.tenant_counters as c (tenant_id, counter, next_value)
  values (p_tenant, p_counter, 2)
  on conflict (tenant_id, counter)
  do update set next_value = c.next_value + 1
  returning next_value - 1 into v_value;
  return v_value;
end
$$;

-- ---------------------------------------------------------------------------
-- RLS for tenancy tables
-- ---------------------------------------------------------------------------
alter table public.tenants enable row level security;
alter table public.app_users enable row level security;
alter table public.tenant_members enable row level security;
alter table public.member_permissions enable row level security;
alter table public.business_profiles enable row level security;
alter table public.tenant_counters enable row level security;

create policy tenants_select on public.tenants
  for select to authenticated
  using (id = (select app.current_tenant_id()));

-- Users see only people in their own business.
create policy app_users_select on public.app_users
  for select to authenticated
  using (
    exists (
      select 1 from public.tenant_members m
      where m.user_id = app_users.id
        and m.tenant_id = (select app.current_tenant_id())
    )
  );

create policy tenant_members_select on public.tenant_members
  for select to authenticated
  using (tenant_id = (select app.current_tenant_id()));

-- Owners see all grants in their tenant; staff see only their own.
create policy member_permissions_select on public.member_permissions
  for select to authenticated
  using (
    tenant_id = (select app.current_tenant_id())
    and ((select app.is_owner()) or user_id = auth.uid())
  );

create policy business_profiles_select on public.business_profiles
  for select to authenticated
  using (tenant_id = (select app.current_tenant_id()));

create policy business_profiles_update on public.business_profiles
  for update to authenticated
  using (tenant_id = (select app.current_tenant_id()) and (select app.is_owner()))
  with check (tenant_id = (select app.current_tenant_id()));

-- Writes to identity/membership go through owner RPCs or the service role
-- only. Column-level grants limit what the profile UPDATE can touch.
revoke all on public.tenants, public.app_users, public.tenant_members,
  public.member_permissions, public.tenant_counters, public.business_profiles
  from anon, authenticated;
grant select on public.tenants, public.app_users, public.tenant_members,
  public.member_permissions, public.business_profiles to authenticated;
grant update (business_name, phone, whatsapp_phone, address, gstin, bill_footer,
  logo_path, watermark_enabled, default_locale)
  on public.business_profiles to authenticated;
