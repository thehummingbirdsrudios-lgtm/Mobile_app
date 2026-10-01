-- Catalogue (Maal), product media metadata, owner-only private product data,
-- customers, customer balances and customer-specific rates.

create type public.product_status as enum ('active', 'archived');
create type public.media_kind as enum ('image', 'video');
create type public.media_status as enum ('pending', 'ready', 'failed');

-- Common write-protection: tenant_id is set from the session, never trusted.
create or replace function app.stamp_tenant() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Service-role/admin scripts (no JWT) may set tenant_id explicitly.
  if auth.uid() is not null then
    new.tenant_id := app.current_tenant_id();
    if new.tenant_id is null then
      perform app.fail('not_authenticated');
    end if;
  end if;
  return new;
end
$$;

-- ---------------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------------
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id),
  name text not null check (length(btrim(name)) between 1 and 60),
  sort_order integer not null default 0,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (tenant_id, id)
);
create unique index categories_name_key on public.categories (tenant_id, lower(name)) where archived_at is null;

-- ---------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------
create table public.products (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id),
  design_no text not null check (design_no ~ '^[A-Za-z0-9][A-Za-z0-9/._-]{0,23}$'),
  name text not null check (length(btrim(name)) between 1 and 120),
  description text check (length(description) <= 1000),
  category_id uuid,
  -- Default selling rate per piece. Cap: ₹1,00,00,000 per piece.
  rate_paise bigint not null check (rate_paise > 0 and rate_paise <= 1000000000),
  weight_mg integer check (weight_mg > 0 and weight_mg <= 100000000),
  is_available boolean not null default true,
  status public.product_status not null default 'active',
  published_at timestamptz not null default now(),
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (tenant_id, id),
  foreign key (tenant_id, category_id) references public.categories (tenant_id, id),
  check ((status = 'archived') = (archived_at is not null))
);
-- Design numbers are unique per tenant, case-insensitively.
create unique index products_design_no_key on public.products (tenant_id, upper(design_no));
-- Prefix lookup "1024…" for search/quick order.
create index products_design_no_prefix on public.products (tenant_id, upper(design_no) text_pattern_ops);
-- Catalogue / Navo Maal keyset pagination.
create index products_catalogue on public.products (tenant_id, published_at desc, id desc) where status = 'active';
create index products_category on public.products (tenant_id, category_id, published_at desc) where status = 'active';
-- Fuzzy name search.
create index products_name_trgm on public.products using gin (name extensions.gin_trgm_ops);

create trigger products_stamp before insert on public.products
  for each row execute function app.stamp_tenant();
create trigger products_touch before update on public.products
  for each row execute function app.touch_row();
create trigger categories_stamp before insert on public.categories
  for each row execute function app.stamp_tenant();
create trigger categories_touch before update on public.categories
  for each row execute function app.touch_row();

-- Owner-only commercial secrets live in a separate table so no staff query,
-- share payload or bill can ever select them by accident.
create table public.product_private (
  tenant_id uuid not null,
  product_id uuid not null,
  cost_paise bigint check (cost_paise >= 0 and cost_paise <= 1000000000),
  supplier_name text check (length(supplier_name) <= 120),
  internal_note text check (length(internal_note) <= 1000),
  updated_at timestamptz not null default now(),
  updated_by uuid,
  primary key (tenant_id, product_id),
  foreign key (tenant_id, product_id) references public.products (tenant_id, id)
);
create trigger product_private_stamp before insert on public.product_private
  for each row execute function app.stamp_tenant();
create trigger product_private_touch before update on public.product_private
  for each row execute function app.touch_row();

-- Media metadata. Binaries live in private Storage under `{tenant_id}/…`.
create table public.product_media (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  product_id uuid not null,
  kind public.media_kind not null,
  status public.media_status not null default 'pending',
  sort_order smallint not null default 0 check (sort_order >= 0),
  mime_type text not null check (mime_type in ('image/jpeg', 'image/png', 'image/webp', 'video/mp4')),
  original_path text not null,
  catalogue_path text,
  share_path text,
  thumb_path text,
  width integer check (width > 0 and width <= 20000),
  height integer check (height > 0 and height <= 20000),
  bytes bigint not null check (bytes > 0 and bytes <= 104857600),
  sha256 text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  unique (tenant_id, id),
  foreign key (tenant_id, product_id) references public.products (tenant_id, id),
  check ((kind = 'image') = (mime_type like 'image/%')),
  check (original_path like tenant_id::text || '/%'),
  check (catalogue_path is null or catalogue_path like tenant_id::text || '/%'),
  check (share_path is null or share_path like tenant_id::text || '/%'),
  check (thumb_path is null or thumb_path like tenant_id::text || '/%'),
  check (status <> 'ready' or kind = 'video' or (catalogue_path is not null and thumb_path is not null))
);
create unique index product_media_dedupe on public.product_media (tenant_id, product_id, sha256) where archived_at is null;
create index product_media_by_product on public.product_media (tenant_id, product_id, sort_order) where archived_at is null;
create trigger product_media_stamp before insert on public.product_media
  for each row execute function app.stamp_tenant();

-- The tenant-prefix CHECKs above compare against the *stamped* tenant_id, so a
-- client cannot register another tenant's storage path as its own media.

-- ---------------------------------------------------------------------------
-- Customers
-- ---------------------------------------------------------------------------
create table public.customers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id),
  name text not null check (length(btrim(name)) between 1 and 120),
  shop_name text check (length(shop_name) <= 120),
  city text check (length(city) <= 60),
  phone text check (phone ~ '^\+?[0-9]{10,15}$'),
  whatsapp_phone text check (whatsapp_phone ~ '^\+?[0-9]{10,15}$'),
  notes text check (length(notes) <= 1000),
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (tenant_id, id)
);
create index customers_by_name on public.customers (tenant_id, lower(name), id) where archived_at is null;
create index customers_name_trgm on public.customers using gin (name extensions.gin_trgm_ops);
create index customers_phone_trgm on public.customers using gin (phone extensions.gin_trgm_ops);
create trigger customers_stamp before insert on public.customers
  for each row execute function app.stamp_tenant();
create trigger customers_touch before update on public.customers
  for each row execute function app.touch_row();

-- Baki is a deliberate denormalisation of SUM(ledger_entries.amount_paise),
-- maintained only by app.post_ledger() inside the same transaction, and kept
-- in its own table so it can be hidden from staff without hisaab.view.
create table public.customer_balances (
  tenant_id uuid not null,
  customer_id uuid not null,
  balance_paise bigint not null default 0,
  last_activity_at timestamptz,
  primary key (tenant_id, customer_id),
  foreign key (tenant_id, customer_id) references public.customers (tenant_id, id)
);
create index customer_balances_baki on public.customer_balances (tenant_id, balance_paise desc) where balance_paise <> 0;

create or replace function app.create_customer_balance() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.customer_balances (tenant_id, customer_id) values (new.tenant_id, new.id);
  return new;
end
$$;
create trigger customers_balance_row after insert on public.customers
  for each row execute function app.create_customer_balance();

-- Customer-specific rate overrides (rate resolution: override → product rate).
create table public.customer_product_rates (
  tenant_id uuid not null,
  customer_id uuid not null,
  product_id uuid not null,
  rate_paise bigint not null check (rate_paise > 0 and rate_paise <= 1000000000),
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid(),
  primary key (tenant_id, customer_id, product_id),
  foreign key (tenant_id, customer_id) references public.customers (tenant_id, id),
  foreign key (tenant_id, product_id) references public.products (tenant_id, id)
);
create trigger customer_product_rates_stamp before insert on public.customer_product_rates
  for each row execute function app.stamp_tenant();
create trigger customer_product_rates_touch before update on public.customer_product_rates
  for each row execute function app.touch_row();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_private enable row level security;
alter table public.product_media enable row level security;
alter table public.customers enable row level security;
alter table public.customer_balances enable row level security;
alter table public.customer_product_rates enable row level security;

-- Every active member can browse Maal and customers (needed to take orders).
create policy categories_select on public.categories for select to authenticated
  using (tenant_id = (select app.current_tenant_id()));
create policy categories_write on public.categories for all to authenticated
  using (tenant_id = (select app.current_tenant_id()) and (select app.has_permission('catalogue.manage')))
  with check (tenant_id = (select app.current_tenant_id()) and (select app.has_permission('catalogue.manage')));

create policy products_select on public.products for select to authenticated
  using (tenant_id = (select app.current_tenant_id()));
create policy products_insert on public.products for insert to authenticated
  with check (tenant_id = (select app.current_tenant_id()) and (select app.has_permission('catalogue.manage')));
create policy products_update on public.products for update to authenticated
  using (tenant_id = (select app.current_tenant_id()) and (select app.has_permission('catalogue.manage')))
  with check (tenant_id = (select app.current_tenant_id()));

create policy product_private_owner on public.product_private for all to authenticated
  using (tenant_id = (select app.current_tenant_id()) and (select app.is_owner()))
  with check (tenant_id = (select app.current_tenant_id()) and (select app.is_owner()));

create policy product_media_select on public.product_media for select to authenticated
  using (tenant_id = (select app.current_tenant_id()));
create policy product_media_insert on public.product_media for insert to authenticated
  with check (tenant_id = (select app.current_tenant_id()) and (select app.has_permission('catalogue.manage')));
create policy product_media_update on public.product_media for update to authenticated
  using (tenant_id = (select app.current_tenant_id()) and (select app.has_permission('catalogue.manage')))
  with check (tenant_id = (select app.current_tenant_id()));

create policy customers_select on public.customers for select to authenticated
  using (tenant_id = (select app.current_tenant_id()));
create policy customers_insert on public.customers for insert to authenticated
  with check (tenant_id = (select app.current_tenant_id()) and (select app.has_permission('customers.manage')));
create policy customers_update on public.customers for update to authenticated
  using (tenant_id = (select app.current_tenant_id()) and (select app.has_permission('customers.manage')))
  with check (tenant_id = (select app.current_tenant_id()));

create policy customer_balances_select on public.customer_balances for select to authenticated
  using (tenant_id = (select app.current_tenant_id()) and (select app.has_permission('hisaab.view')));

-- Staff taking orders see the rate they will charge; editing needs rates.manage.
create policy customer_product_rates_select on public.customer_product_rates for select to authenticated
  using (tenant_id = (select app.current_tenant_id()));
create policy customer_product_rates_write on public.customer_product_rates for all to authenticated
  using (tenant_id = (select app.current_tenant_id()) and (select app.has_permission('rates.manage')))
  with check (tenant_id = (select app.current_tenant_id()) and (select app.has_permission('rates.manage')));

-- Rate changes on products need rates.manage in addition to catalogue.manage.
create or replace function app.guard_product_rate() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null
     and new.rate_paise is distinct from old.rate_paise
     and not app.has_permission('rates.manage') then
    perform app.fail('permission_denied');
  end if;
  return new;
end
$$;
create trigger products_rate_guard before update of rate_paise on public.products
  for each row execute function app.guard_product_rate();

-- Column-level grants: clients can never write tenant_id, ids, audit columns
-- or balances. Deletes are not granted — archive instead.
revoke all on public.categories, public.products, public.product_private, public.product_media,
  public.customers, public.customer_balances, public.customer_product_rates from anon, authenticated;

grant select on public.categories, public.products, public.product_private, public.product_media,
  public.customers, public.customer_balances, public.customer_product_rates to authenticated;

grant insert (name, sort_order) on public.categories to authenticated;
grant update (name, sort_order, archived_at) on public.categories to authenticated;

grant insert (design_no, name, description, category_id, rate_paise, weight_mg, is_available, published_at)
  on public.products to authenticated;
grant update (design_no, name, description, category_id, rate_paise, weight_mg, is_available,
  status, archived_at, published_at)
  on public.products to authenticated;

grant insert (product_id, cost_paise, supplier_name, internal_note) on public.product_private to authenticated;
grant update (cost_paise, supplier_name, internal_note) on public.product_private to authenticated;

grant insert (product_id, kind, sort_order, mime_type, original_path, catalogue_path, share_path,
  thumb_path, width, height, bytes, sha256, status)
  on public.product_media to authenticated;
grant update (sort_order, status, catalogue_path, share_path, thumb_path, width, height, archived_at)
  on public.product_media to authenticated;

grant insert (name, shop_name, city, phone, whatsapp_phone, notes) on public.customers to authenticated;
grant update (name, shop_name, city, phone, whatsapp_phone, notes, archived_at) on public.customers to authenticated;

grant insert (customer_id, product_id, rate_paise) on public.customer_product_rates to authenticated;
grant update (rate_paise) on public.customer_product_rates to authenticated;
grant delete on public.customer_product_rates to authenticated;
