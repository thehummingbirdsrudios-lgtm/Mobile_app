-- Read models for the app screens. All are SECURITY INVOKER (RLS applies on
-- top of the explicit tenant filters) except where noted. Results are
-- bounded and keyset-paginated. Composite reads live here — not in client
-- query strings — so they are tested against real Postgres.

-- ---------------------------------------------------------------------------
-- Catalogue: product detail with gallery and (owner-only) private data
-- ---------------------------------------------------------------------------
create or replace function public.product_detail(p_product_id uuid) returns jsonb
language sql stable security invoker
as $$
  select jsonb_build_object(
    'id', p.id,
    'design_no', p.design_no,
    'name', p.name,
    'description', p.description,
    'category_id', p.category_id,
    'category_name', c.name,
    'rate_paise', p.rate_paise,
    'weight_mg', p.weight_mg,
    'is_available', p.is_available,
    'status', p.status,
    'published_at', p.published_at,
    'media', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', m.id, 'kind', m.kind, 'catalogue_path', m.catalogue_path, 'thumb_path', m.thumb_path,
               'share_path', m.share_path, 'width', m.width, 'height', m.height, 'sort_order', m.sort_order)
             order by m.sort_order, m.created_at)
        from public.product_media m
       where m.tenant_id = p.tenant_id and m.product_id = p.id
         and m.status = 'ready' and m.archived_at is null), '[]'::jsonb),
    -- product_private RLS returns no row for staff, so this is null for them.
    'private', (select jsonb_build_object('cost_paise', pp.cost_paise, 'supplier_name', pp.supplier_name,
                                          'internal_note', pp.internal_note)
                  from public.product_private pp
                 where pp.tenant_id = p.tenant_id and pp.product_id = p.id)
  )
  from public.products p
  left join public.categories c on c.tenant_id = p.tenant_id and c.id = p.category_id
  where p.tenant_id = (select app.current_tenant_id()) and p.id = p_product_id
$$;

-- Effective rates and orderability for a cart / quick order, by id or by
-- design number (case-insensitive). Unknown design numbers come back with
-- product_id null so the UI can point at the exact line.
create or replace function public.quote_products(
  p_customer_id uuid,
  p_product_ids uuid[] default null,
  p_design_nos text[] default null
) returns table (
  input text, product_id uuid, design_no text, name text, rate_paise bigint, default_rate_paise bigint,
  weight_mg integer, is_orderable boolean, thumb_path text
)
language sql stable security invoker
as $$
  with t as (select app.current_tenant_id() as tenant_id),
  wanted as (
    select x.id::text as input, x.id as product_id, null::text as design_key
      from unnest(coalesce(p_product_ids, '{}')) as x(id)
    union all
    select d, null, upper(btrim(d)) from unnest(coalesce(p_design_nos, '{}')) as d
  )
  select w.input, p.id, p.design_no, p.name,
         case when p.id is null then null else app.resolve_rate(p.tenant_id, p_customer_id, p.id) end,
         p.rate_paise, p.weight_mg,
         coalesce(p.status = 'active' and p.is_available, false),
         case when p.id is null then null else app.primary_thumb(p.tenant_id, p.id) end
    from wanted w
    cross join t
    left join public.products p
      on p.tenant_id = t.tenant_id
     and ((w.product_id is not null and p.id = w.product_id)
          or (w.design_key is not null and upper(p.design_no) = w.design_key))
   limit 200
$$;

-- ---------------------------------------------------------------------------
-- Customers
-- ---------------------------------------------------------------------------
-- p_sort: 'name' (all active customers, A→Z) or 'baki' (non-zero Baki, high→low;
-- requires hisaab.view — otherwise falls back to name). Keyset cursor =
-- (p_after_key, p_after_id) taken from the last row's sort_key / id.
create or replace function public.customer_list(
  p_search text default null,
  p_sort text default 'name',
  p_after_key text default null,
  p_after_id uuid default null,
  p_limit integer default 30
) returns table (
  id uuid, name text, shop_name text, city text, phone text, whatsapp_phone text,
  balance_paise bigint, last_activity_at timestamptz, sort_key text
)
language plpgsql stable security invoker
as $$
declare
  v_tenant uuid := app.current_tenant_id();
  v_limit integer := least(greatest(coalesce(p_limit, 30), 1), 100);
  v_q text := nullif(btrim(coalesce(p_search, '')), '');
  v_like text := case when v_q is null then null else '%' || app.like_escape(v_q) || '%' end;
  v_digits text := regexp_replace(coalesce(v_q, ''), '[^0-9]', '', 'g');
begin
  if v_tenant is null then
    return;
  end if;

  if p_sort = 'baki' and app.has_permission('hisaab.view') then
    return query
    select c.id, c.name, c.shop_name, c.city, c.phone, c.whatsapp_phone, b.balance_paise, b.last_activity_at,
           lpad((9000000000000000000 - b.balance_paise)::text, 20, '0')
      from public.customer_balances b
      join public.customers c on c.tenant_id = b.tenant_id and c.id = b.customer_id
     where b.tenant_id = v_tenant and b.balance_paise <> 0 and c.archived_at is null
       and (v_like is null or c.name ilike v_like or (length(v_digits) >= 4 and c.phone like '%' || v_digits || '%'))
       and (p_after_key is null
            or (lpad((9000000000000000000 - b.balance_paise)::text, 20, '0'), c.id) > (p_after_key, p_after_id))
     order by b.balance_paise desc, c.id
     limit v_limit;
    return;
  end if;

  return query
  select c.id, c.name, c.shop_name, c.city, c.phone, c.whatsapp_phone,
         b.balance_paise, b.last_activity_at, lower(c.name)
    from public.customers c
    left join public.customer_balances b on b.tenant_id = c.tenant_id and b.customer_id = c.id
   where c.tenant_id = v_tenant and c.archived_at is null
     and (v_like is null or c.name ilike v_like or (length(v_digits) >= 4 and c.phone like '%' || v_digits || '%'))
     and (p_after_key is null or (lower(c.name), c.id) > (p_after_key, p_after_id))
   order by lower(c.name), c.id
   limit v_limit;
end
$$;

create or replace function public.customer_detail(p_customer_id uuid) returns jsonb
language sql stable security invoker
as $$
  select jsonb_build_object(
    'id', c.id, 'name', c.name, 'shop_name', c.shop_name, 'city', c.city, 'phone', c.phone,
    'whatsapp_phone', c.whatsapp_phone, 'notes', c.notes, 'archived', c.archived_at is not null,
    'created_at', c.created_at,
    -- customer_balances RLS hides this without hisaab.view → null.
    'balance_paise', (select b.balance_paise from public.customer_balances b
                       where b.tenant_id = c.tenant_id and b.customer_id = c.id),
    'order_count', (select count(*) from public.orders o
                     where o.tenant_id = c.tenant_id and o.customer_id = c.id and o.status <> 'cancelled'),
    'open_orders', (select count(*) from public.orders o
                     where o.tenant_id = c.tenant_id and o.customer_id = c.id
                       and o.status in ('confirmed', 'processing', 'ready')),
    'last_order_at', (select max(o.created_at) from public.orders o
                       where o.tenant_id = c.tenant_id and o.customer_id = c.id and o.status <> 'cancelled'),
    'special_rates', (select count(*) from public.customer_product_rates r
                       where r.tenant_id = c.tenant_id and r.customer_id = c.id)
  )
  from public.customers c
  where c.tenant_id = (select app.current_tenant_id()) and c.id = p_customer_id
$$;

create or replace function public.customer_rates(p_customer_id uuid) returns table (
  product_id uuid, design_no text, name text, default_rate_paise bigint, rate_paise bigint
)
language sql stable security invoker
as $$
  select p.id, p.design_no, p.name, p.rate_paise, r.rate_paise
    from public.customer_product_rates r
    join public.products p on p.tenant_id = r.tenant_id and p.id = r.product_id
   where r.tenant_id = (select app.current_tenant_id()) and r.customer_id = p_customer_id
   order by p.design_no
   limit 500
$$;

-- ---------------------------------------------------------------------------
-- Orders
-- ---------------------------------------------------------------------------
-- p_scope: 'all' | 'pending' (confirmed/processing/ready). Newest first.
create or replace function public.order_list(
  p_customer_id uuid default null,
  p_scope text default 'all',
  p_before_at timestamptz default null,
  p_before_id uuid default null,
  p_limit integer default 30
) returns table (
  id uuid, order_no bigint, customer_id uuid, customer_name text, status public.order_status,
  total_qty integer, total_paise bigint, created_at timestamptz, bill_id uuid
)
language sql stable security invoker
as $$
  select o.id, o.order_no, o.customer_id, c.name, o.status, o.total_qty, o.total_paise, o.created_at,
         (select b.id from public.bills b where b.tenant_id = o.tenant_id and b.order_id = o.id)
    from public.orders o
    join public.customers c on c.tenant_id = o.tenant_id and c.id = o.customer_id
   where o.tenant_id = (select app.current_tenant_id())
     and (p_customer_id is null or o.customer_id = p_customer_id)
     and (coalesce(p_scope, 'all') <> 'pending' or o.status in ('confirmed', 'processing', 'ready'))
     and (p_before_at is null or (o.created_at, o.id) < (p_before_at, p_before_id))
   order by o.created_at desc, o.id desc
   limit least(greatest(coalesce(p_limit, 30), 1), 100)
$$;

create or replace function public.order_detail(p_order_id uuid) returns jsonb
language sql stable security invoker
as $$
  select jsonb_build_object(
    'id', o.id, 'order_no', o.order_no, 'status', o.status, 'total_qty', o.total_qty,
    'total_paise', o.total_paise, 'total_weight_mg', o.total_weight_mg, 'note', o.note,
    'reorder_of', o.reorder_of, 'cancel_reason', o.cancel_reason, 'created_at', o.created_at,
    'created_by_name', (select u.display_name from public.app_users u where u.id = o.created_by),
    'customer', jsonb_build_object('id', c.id, 'name', c.name, 'phone', c.phone,
                                   'whatsapp_phone', c.whatsapp_phone, 'city', c.city),
    'items', (select jsonb_agg(jsonb_build_object(
                       'product_id', i.product_id, 'design_no', i.design_no, 'name', i.product_name,
                       'thumb_path', i.thumb_path, 'rate_paise', i.rate_paise, 'qty', i.qty,
                       'amount_paise', i.amount_paise, 'weight_mg', i.weight_mg) order by i.line_no)
                from public.order_items i where i.tenant_id = o.tenant_id and i.order_id = o.id),
    -- bills/payments RLS hide these from members without the permission.
    'bill', (select jsonb_build_object('id', b.id, 'bill_no', b.bill_no, 'issued_at', b.issued_at)
               from public.bills b where b.tenant_id = o.tenant_id and b.order_id = o.id),
    'payments', coalesce((select jsonb_agg(jsonb_build_object(
                               'id', p.id, 'payment_no', p.payment_no, 'amount_paise', p.amount_paise,
                               'mode', p.mode, 'received_at', p.received_at) order by p.received_at)
                            from public.payments p where p.tenant_id = o.tenant_id and p.order_id = o.id),
                         '[]'::jsonb)
  )
  from public.orders o
  join public.customers c on c.tenant_id = o.tenant_id and c.id = o.customer_id
  where o.tenant_id = (select app.current_tenant_id()) and o.id = p_order_id
$$;

-- ---------------------------------------------------------------------------
-- Hisaab and receipts
-- ---------------------------------------------------------------------------
create or replace function public.ledger_page(
  p_customer_id uuid,
  p_before_at timestamptz default null,
  p_before_id uuid default null,
  p_limit integer default 50
) returns table (
  id uuid, kind public.ledger_kind, amount_paise bigint, balance_after_paise bigint, order_id uuid,
  order_no bigint, payment_id uuid, payment_mode public.payment_mode, note text, created_at timestamptz
)
language sql stable security invoker
as $$
  select l.id, l.kind, l.amount_paise, l.balance_after_paise, l.order_id, o.order_no, l.payment_id, p.mode,
         l.note, l.created_at
    from public.ledger_entries l
    left join public.orders o on o.tenant_id = l.tenant_id and o.id = l.order_id
    left join public.payments p on p.tenant_id = l.tenant_id and p.id = l.payment_id
   where l.tenant_id = (select app.current_tenant_id()) and l.customer_id = p_customer_id
     and (p_before_at is null or (l.created_at, l.id) < (p_before_at, p_before_id))
   order by l.created_at desc, l.id desc
   limit least(greatest(coalesce(p_limit, 50), 1), 200)
$$;

-- Customer-safe receipt payload (allow-listed fields only).
create or replace function public.payment_receipt(p_payment_id uuid) returns jsonb
language sql stable security invoker
as $$
  select jsonb_build_object(
    'payment_no', p.payment_no, 'amount_paise', p.amount_paise, 'mode', p.mode, 'reference', p.reference,
    'received_at', p.received_at, 'balance_before_paise', p.balance_before_paise,
    'balance_after_paise', p.balance_after_paise,
    'customer_name', c.name, 'customer_phone', coalesce(c.whatsapp_phone, c.phone),
    'business_name', b.business_name, 'business_phone', b.phone, 'business_address', b.address,
    'gstin', b.gstin
  )
  from public.payments p
  join public.customers c on c.tenant_id = p.tenant_id and c.id = p.customer_id
  join public.business_profiles b on b.tenant_id = p.tenant_id
  where p.tenant_id = (select app.current_tenant_id()) and p.id = p_payment_id
$$;

-- ---------------------------------------------------------------------------
-- Owner: staff list and audit log (SECURITY DEFINER + require_owner)
-- ---------------------------------------------------------------------------
create or replace function public.member_list() returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_owner();
begin
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'user_id', m.user_id, 'username', u.username, 'display_name', u.display_name,
             'role', m.role, 'is_active', m.is_active,
             'permissions', coalesce((select jsonb_agg(mp.permission order by mp.permission)
                                        from public.member_permissions mp
                                       where mp.tenant_id = m.tenant_id and mp.user_id = m.user_id), '[]'::jsonb))
           order by m.role, u.display_name)
      from public.tenant_members m
      join public.app_users u on u.id = m.user_id
     where m.tenant_id = v_tenant), '[]'::jsonb);
end
$$;

create or replace function public.audit_page(p_before_id bigint default null, p_limit integer default 50)
returns table (id bigint, action text, entity text, entity_id uuid, data jsonb, actor_name text, created_at timestamptz)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_owner();
begin
  return query
  select a.id, a.action, a.entity, a.entity_id, a.data, u.display_name, a.created_at
    from public.audit_logs a
    left join public.app_users u on u.id = a.actor_id
   where a.tenant_id = v_tenant and (p_before_id is null or a.id < p_before_id)
   order by a.id desc
   limit least(greatest(coalesce(p_limit, 50), 1), 200);
end
$$;

revoke all on function
  public.product_detail(uuid),
  public.quote_products(uuid, uuid[], text[]),
  public.customer_list(text, text, text, uuid, integer),
  public.customer_detail(uuid),
  public.customer_rates(uuid),
  public.order_list(uuid, text, timestamptz, uuid, integer),
  public.order_detail(uuid),
  public.ledger_page(uuid, timestamptz, uuid, integer),
  public.payment_receipt(uuid),
  public.member_list(),
  public.audit_page(bigint, integer)
  from public, anon;

grant execute on function
  public.product_detail(uuid),
  public.quote_products(uuid, uuid[], text[]),
  public.customer_list(text, text, text, uuid, integer),
  public.customer_detail(uuid),
  public.customer_rates(uuid),
  public.order_list(uuid, text, timestamptz, uuid, integer),
  public.order_detail(uuid),
  public.ledger_page(uuid, timestamptz, uuid, integer),
  public.payment_receipt(uuid),
  public.member_list(),
  public.audit_page(bigint, integer)
  to authenticated;

-- Supporting index for the Baki keyset path's tie-breaker is covered by
-- customer_balances_baki; ledger and order paths use existing indexes.
