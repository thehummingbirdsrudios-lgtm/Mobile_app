-- Owner data export (CSV built on the device).
--
-- Owner-only: each function refuses anyone else before reading. They are
-- SECURITY INVOKER, so RLS still pins every row to the caller's business.
-- All are keyset-paged (stable under concurrent writes, index-backed) and
-- capped per page; the app loops pages.

create index ledger_recent on public.ledger_entries (tenant_id, created_at, id);

-- The caller's business if they are its active owner; fails otherwise.
-- Invoker-safe: uses only helpers granted to authenticated.
create or replace function app.export_owner_tenant() returns uuid
language plpgsql stable
set search_path = ''
as $$
begin
  if not coalesce(app.is_owner(), false) then
    perform app.fail('permission_denied');
  end if;
  return app.current_tenant_id();
end
$$;
revoke all on function app.export_owner_tenant() from public;
grant execute on function app.export_owner_tenant() to authenticated;

create or replace function public.export_customers(p_after uuid default null, p_limit integer default 500)
returns table (
  id uuid, name text, shop_name text, city text, phone text, whatsapp_phone text,
  balance_paise bigint, archived boolean, created_at timestamptz
)
language plpgsql stable security invoker
set search_path = ''
as $$
declare
  v_tenant uuid := app.export_owner_tenant();
begin
  return query
  select c.id, c.name, c.shop_name, c.city, c.phone, c.whatsapp_phone,
         coalesce(b.balance_paise, 0), c.archived_at is not null, c.created_at
    from public.customers c
    left join public.customer_balances b on b.tenant_id = c.tenant_id and b.customer_id = c.id
   where c.tenant_id = v_tenant and (p_after is null or c.id > p_after)
   order by c.id
   limit least(greatest(coalesce(p_limit, 500), 1), 1000);
end
$$;

create or replace function public.export_ledger(
  p_from timestamptz, p_to timestamptz,
  p_after_at timestamptz default null, p_after_id uuid default null, p_limit integer default 500
) returns table (
  id uuid, created_at timestamptz, customer_name text, kind text, amount_paise bigint,
  balance_after_paise bigint, order_no bigint, payment_mode text, payment_reference text, note text
)
language plpgsql stable security invoker
set search_path = ''
as $$
declare
  v_tenant uuid := app.export_owner_tenant();
begin
  return query
  select l.id, l.created_at, c.name, l.kind::text, l.amount_paise, l.balance_after_paise,
         o.order_no, p.mode::text, p.reference, l.note
    from public.ledger_entries l
    join public.customers c on c.tenant_id = l.tenant_id and c.id = l.customer_id
    left join public.orders o on o.tenant_id = l.tenant_id and o.id = l.order_id
    left join public.payments p on p.tenant_id = l.tenant_id and p.id = l.payment_id
   where l.tenant_id = v_tenant
     and l.created_at >= p_from and l.created_at < p_to
     and (p_after_at is null or (l.created_at, l.id) > (p_after_at, p_after_id))
   order by l.created_at, l.id
   limit least(greatest(coalesce(p_limit, 500), 1), 1000);
end
$$;

create or replace function public.export_orders(
  p_from timestamptz, p_to timestamptz,
  p_after_at timestamptz default null, p_after_id uuid default null, p_limit integer default 500
) returns table (
  id uuid, created_at timestamptz, order_no bigint, customer_name text, status text,
  total_qty bigint, total_paise bigint, total_weight_mg bigint, note text
)
language plpgsql stable security invoker
set search_path = ''
as $$
declare
  v_tenant uuid := app.export_owner_tenant();
begin
  return query
  select o.id, o.created_at, o.order_no, c.name, o.status::text, o.total_qty::bigint, o.total_paise,
         o.total_weight_mg, o.note
    from public.orders o
    join public.customers c on c.tenant_id = o.tenant_id and c.id = o.customer_id
   where o.tenant_id = v_tenant
     and o.created_at >= p_from and o.created_at < p_to
     and (p_after_at is null or (o.created_at, o.id) > (p_after_at, p_after_id))
   order by o.created_at, o.id
   limit least(greatest(coalesce(p_limit, 500), 1), 1000);
end
$$;

-- Lines of up to p_limit orders per page (an order's lines never split).
create or replace function public.export_order_items(
  p_from timestamptz, p_to timestamptz,
  p_after_at timestamptz default null, p_after_id uuid default null, p_limit integer default 200
) returns table (
  order_id uuid, order_created_at timestamptz, order_no bigint, customer_name text, line_no integer,
  design_no text, product_name text, qty integer, rate_paise bigint, amount_paise bigint, weight_mg bigint
)
language plpgsql stable security invoker
set search_path = ''
as $$
declare
  v_tenant uuid := app.export_owner_tenant();
begin
  return query
  with page as (
    select o.id, o.created_at, o.order_no, o.customer_id
      from public.orders o
     where o.tenant_id = v_tenant
       and o.created_at >= p_from and o.created_at < p_to
       and (p_after_at is null or (o.created_at, o.id) > (p_after_at, p_after_id))
     order by o.created_at, o.id
     limit least(greatest(coalesce(p_limit, 200), 1), 500)
  )
  select pg.id, pg.created_at, pg.order_no, c.name, i.line_no::integer, i.design_no, i.product_name,
         i.qty::integer, i.rate_paise, i.amount_paise, i.weight_mg::bigint
    from page pg
    join public.customers c on c.tenant_id = v_tenant and c.id = pg.customer_id
    join public.order_items i on i.tenant_id = v_tenant and i.order_id = pg.id
   order by pg.created_at, pg.id, i.line_no;
end
$$;

-- Designs with the owner's private cost and supplier (owner-only file).
create or replace function public.export_designs(p_after uuid default null, p_limit integer default 500)
returns table (
  id uuid, design_no text, name text, category text, rate_paise bigint, weight_mg bigint,
  is_available boolean, archived boolean, published_at timestamptz, cost_paise bigint, supplier_name text
)
language plpgsql stable security invoker
set search_path = ''
as $$
declare
  v_tenant uuid := app.export_owner_tenant();
begin
  return query
  select p.id, p.design_no, p.name, cat.name, p.rate_paise::bigint, p.weight_mg::bigint, p.is_available,
         p.status = 'archived', p.published_at, pp.cost_paise, pp.supplier_name
    from public.products p
    left join public.categories cat on cat.tenant_id = p.tenant_id and cat.id = p.category_id
    left join public.product_private pp on pp.tenant_id = p.tenant_id and pp.product_id = p.id
   where p.tenant_id = v_tenant and (p_after is null or p.id > p_after)
   order by p.id
   limit least(greatest(coalesce(p_limit, 500), 1), 1000);
end
$$;

revoke all on function
  public.export_customers(uuid, integer),
  public.export_ledger(timestamptz, timestamptz, timestamptz, uuid, integer),
  public.export_orders(timestamptz, timestamptz, timestamptz, uuid, integer),
  public.export_order_items(timestamptz, timestamptz, timestamptz, uuid, integer),
  public.export_designs(uuid, integer)
  from public, anon;

grant execute on function
  public.export_customers(uuid, integer),
  public.export_ledger(timestamptz, timestamptz, timestamptz, uuid, integer),
  public.export_orders(timestamptz, timestamptz, timestamptz, uuid, integer),
  public.export_order_items(timestamptz, timestamptz, timestamptz, uuid, integer),
  public.export_designs(uuid, integer)
  to authenticated;
