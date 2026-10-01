-- Read-side RPCs. SECURITY INVOKER wherever possible so RLS applies on top of
-- the explicit tenant filters. Results are bounded (limits are clamped).

-- Escape LIKE metacharacters so user input is matched literally.
create or replace function app.like_escape(p text) returns text
language sql immutable
set search_path = ''
as $$
  select replace(replace(replace(p, '\', '\\'), '%', '\%'), '_', '\_')
$$;
grant execute on function app.like_escape(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Universal search: one box for design no, design name, customer name/phone
-- and order number. Grouped, ranked and capped per group.
-- ---------------------------------------------------------------------------
create or replace function public.search_all(p_query text, p_limit integer default 8)
returns table (kind text, id uuid, title text, subtitle text, rank real)
language plpgsql stable security invoker
set search_path = ''
as $$
declare
  v_tenant uuid := app.current_tenant_id();
  v_q text := btrim(coalesce(p_query, ''));
  v_like text;
  v_digits text;
  v_limit integer := least(greatest(coalesce(p_limit, 8), 1), 25);
begin
  if v_tenant is null or length(v_q) = 0 or length(v_q) > 60 then
    return;
  end if;
  v_like := app.like_escape(v_q);
  v_digits := regexp_replace(v_q, '[^0-9]', '', 'g');

  -- Designs: exact/prefix design number first, then fuzzy name.
  return query
  select 'product'::text, p.id, p.design_no, p.name,
         (case when upper(p.design_no) = upper(v_q) then 3
               when upper(p.design_no) like upper(v_like) || '%' then 2
               else extensions.similarity(p.name, v_q) end)::real as rank
    from public.products p
   where p.tenant_id = v_tenant
     and p.status = 'active'
     and (upper(p.design_no) like upper(v_like) || '%' or p.name ilike '%' || v_like || '%')
   order by rank desc, p.design_no
   limit v_limit;

  -- Customers: name or phone digits.
  return query
  select 'customer'::text, c.id, c.name, coalesce(c.shop_name, c.city, c.phone),
         (case when lower(c.name) = lower(v_q) then 3
               when c.name ilike v_like || '%' then 2
               else extensions.similarity(c.name, v_q) end)::real as rank
    from public.customers c
   where c.tenant_id = v_tenant
     and c.archived_at is null
     and (c.name ilike '%' || v_like || '%'
          or (length(v_digits) >= 4 and c.phone like '%' || v_digits || '%'))
   order by rank desc, c.name
   limit v_limit;

  -- Orders: by number ("1045" or "Order 1045").
  if length(v_digits) between 1 and 12 then
    return query
    select 'order'::text, o.id, o.order_no::text, c.name, 3::real
      from public.orders o
      join public.customers c on c.tenant_id = o.tenant_id and c.id = o.customer_id
     where o.tenant_id = v_tenant and o.order_no = v_digits::bigint;
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- Catalogue page (keyset pagination; newest first). p_new_since filters Navo Maal.
-- ---------------------------------------------------------------------------
create or replace function public.catalogue_page(
  p_after_published_at timestamptz default null,
  p_after_id uuid default null,
  p_limit integer default 30,
  p_category_id uuid default null,
  p_new_since timestamptz default null
) returns table (
  id uuid, design_no text, name text, rate_paise bigint, weight_mg integer,
  is_available boolean, published_at timestamptz, thumb_path text, catalogue_path text
)
language sql stable security invoker
-- No SET clause: lets the planner inline this function into the caller's
-- query (all names are schema-qualified; SECURITY INVOKER keeps RLS).
as $$
  select p.id, p.design_no, p.name, p.rate_paise, p.weight_mg, p.is_available, p.published_at,
         m.thumb_path, m.catalogue_path
    from public.products p
    left join lateral (
      select pm.thumb_path, pm.catalogue_path
        from public.product_media pm
       where pm.tenant_id = p.tenant_id and pm.product_id = p.id
         and pm.kind = 'image' and pm.status = 'ready' and pm.archived_at is null
       order by pm.sort_order, pm.created_at
       limit 1
    ) m on true
   where p.tenant_id = (select app.current_tenant_id())
     and p.status = 'active'
     and (p_category_id is null or p.category_id = p_category_id)
     and (p_new_since is null or p.published_at >= p_new_since)
     and (p_after_published_at is null
          or (p.published_at, p.id) < (p_after_published_at, p_after_id))
   order by p.published_at desc, p.id desc
   limit least(greatest(coalesce(p_limit, 30), 1), 100)
$$;

-- ---------------------------------------------------------------------------
-- Regular Maal: designs a customer buys again and again.
-- ---------------------------------------------------------------------------
create or replace function public.regular_maal(p_customer_id uuid, p_limit integer default 20)
returns table (
  product_id uuid, design_no text, name text, times_ordered bigint, total_qty bigint,
  last_qty integer, last_ordered_at timestamptz, rate_paise bigint, is_orderable boolean, thumb_path text
)
language sql stable security invoker
-- No SET clause: lets the planner inline this function into the caller's
-- query (all names are schema-qualified; SECURITY INVOKER keeps RLS).
as $$
  with t as (select app.current_tenant_id() as tenant_id),
  hist as (
    select i.product_id,
           count(*) as times_ordered,
           sum(i.qty)::bigint as total_qty,
           max(o.created_at) as last_ordered_at,
           (array_agg(i.qty order by o.created_at desc))[1] as last_qty
      from public.order_items i
      join public.orders o on o.tenant_id = i.tenant_id and o.id = i.order_id
      join t on t.tenant_id = i.tenant_id
     where i.customer_id = p_customer_id and o.status <> 'cancelled'
     group by i.product_id
  )
  select p.id, p.design_no, p.name, h.times_ordered, h.total_qty, h.last_qty, h.last_ordered_at,
         app.resolve_rate(p.tenant_id, p_customer_id, p.id),
         (p.status = 'active' and p.is_available),
         app.primary_thumb(p.tenant_id, p.id)
    from hist h
    join t on true
    join public.products p on p.tenant_id = t.tenant_id and p.id = h.product_id
   order by h.times_ordered desc, h.last_ordered_at desc
   limit least(greatest(coalesce(p_limit, 20), 1), 50)
$$;

-- ---------------------------------------------------------------------------
-- Fari Order preview: previous order's lines with TODAY's rate & availability.
-- The client edits quantities and submits via create_order(reorder_of => …).
-- ---------------------------------------------------------------------------
create or replace function public.reorder_preview(p_order_id uuid)
returns table (
  product_id uuid, design_no text, name text, qty integer, old_rate_paise bigint,
  rate_paise bigint, is_orderable boolean, thumb_path text
)
language sql stable security invoker
-- No SET clause: lets the planner inline this function into the caller's
-- query (all names are schema-qualified; SECURITY INVOKER keeps RLS).
as $$
  select i.product_id, p.design_no, p.name, i.qty, i.rate_paise,
         app.resolve_rate(i.tenant_id, i.customer_id, i.product_id),
         (p.status = 'active' and p.is_available),
         coalesce(app.primary_thumb(i.tenant_id, i.product_id), i.thumb_path)
    from public.order_items i
    join public.products p on p.tenant_id = i.tenant_id and p.id = i.product_id
   where i.tenant_id = (select app.current_tenant_id()) and i.order_id = p_order_id
   order by i.line_no
$$;

-- ---------------------------------------------------------------------------
-- Safe share payloads. These are the ONLY sources for external sharing.
-- They return an explicit allow-list of fields — never cost, supplier,
-- internal notes, other customers' rates, stock or internal ids beyond the
-- one being shared.
-- ---------------------------------------------------------------------------
create or replace function public.share_product(p_product_id uuid, p_customer_id uuid default null)
returns jsonb
language plpgsql stable security invoker
set search_path = ''
as $$
declare
  v_tenant uuid := app.current_tenant_id();
  v_result jsonb;
begin
  if v_tenant is null then
    perform app.fail('not_authenticated');
  end if;
  if p_customer_id is not null and not exists (
    select 1 from public.customers where tenant_id = v_tenant and id = p_customer_id) then
    perform app.fail('customer_not_found');
  end if;

  select jsonb_build_object(
           'design_no', p.design_no,
           'name', p.name,
           'rate_paise', app.resolve_rate(v_tenant, p_customer_id, p.id),
           'weight_mg', p.weight_mg,
           'share_path', (select pm.share_path from public.product_media pm
                           where pm.tenant_id = v_tenant and pm.product_id = p.id and pm.kind = 'image'
                             and pm.status = 'ready' and pm.archived_at is null
                           order by pm.sort_order, pm.created_at limit 1),
           'business_name', b.business_name,
           'whatsapp_phone', b.whatsapp_phone,
           'watermark_enabled', b.watermark_enabled)
    into v_result
    from public.products p
    join public.business_profiles b on b.tenant_id = p.tenant_id
   where p.tenant_id = v_tenant and p.id = p_product_id and p.status = 'active';

  if v_result is null then
    perform app.fail('product_not_found');
  end if;
  return v_result;
end
$$;

create or replace function public.bill_payload(p_bill_id uuid) returns jsonb
language plpgsql stable security invoker
set search_path = ''
as $$
declare
  v_tenant uuid := app.current_tenant_id();
  v_result jsonb;
begin
  if v_tenant is null then
    perform app.fail('not_authenticated');
  end if;

  -- bills RLS already requires bills.issue or hisaab.view.
  select jsonb_build_object(
           'bill_no', b.bill_no,
           'issued_at', b.issued_at,
           'order_no', o.order_no,
           'order_status', o.status,
           'customer_name', b.customer_name,
           'customer_phone', b.customer_phone,
           'business', b.business_snapshot,
           'total_qty', b.total_qty,
           'total_paise', b.total_paise,
           'total_weight_mg', b.total_weight_mg,
           'paid_paise', b.paid_paise,
           'balance_after_paise', b.balance_after_paise,
           'items', (select jsonb_agg(jsonb_build_object(
                              'design_no', i.design_no,
                              'name', i.product_name,
                              'qty', i.qty,
                              'rate_paise', i.rate_paise,
                              'amount_paise', i.amount_paise,
                              'weight_mg', i.weight_mg,
                              'thumb_path', i.thumb_path) order by i.line_no)
                       from public.order_items i
                      where i.tenant_id = b.tenant_id and i.order_id = b.order_id))
    into v_result
    from public.bills b
    join public.orders o on o.tenant_id = b.tenant_id and o.id = b.order_id
   where b.tenant_id = v_tenant and b.id = p_bill_id;

  if v_result is null then
    perform app.fail('bill_not_found');
  end if;
  return v_result;
end
$$;

-- ---------------------------------------------------------------------------
-- Owner dashboard: "Aaje shu che?" — today's numbers in the tenant timezone.
-- SECURITY DEFINER because reports.view grants aggregate totals without
-- granting row-level Hisaab access.
-- ---------------------------------------------------------------------------
create or replace function public.dashboard_summary() returns jsonb
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_permission('reports.view');
  v_tz text;
  v_day_start timestamptz;
begin
  select timezone into v_tz from public.business_profiles where tenant_id = v_tenant;
  v_day_start := (date_trunc('day', now() at time zone coalesce(v_tz, 'Asia/Kolkata')))
                 at time zone coalesce(v_tz, 'Asia/Kolkata');

  return jsonb_build_object(
    'day_start', v_day_start,
    'sales_today_paise', (select coalesce(sum(total_paise), 0) from public.orders
                           where tenant_id = v_tenant and created_at >= v_day_start and status <> 'cancelled'),
    'orders_today', (select count(*) from public.orders
                      where tenant_id = v_tenant and created_at >= v_day_start and status <> 'cancelled'),
    'payments_today_paise', (select coalesce(sum(amount_paise), 0) from public.payments
                              where tenant_id = v_tenant and received_at >= v_day_start),
    'total_baki_paise', (select coalesce(sum(balance_paise), 0) from public.customer_balances
                          where tenant_id = v_tenant and balance_paise > 0),
    'pending_orders', (select count(*) from public.orders
                        where tenant_id = v_tenant and status in ('confirmed', 'processing', 'ready')),
    'new_maal_7d', (select count(*) from public.products
                     where tenant_id = v_tenant and status = 'active' and published_at >= now() - interval '7 days')
  );
end
$$;

revoke all on function
  public.search_all(text, integer),
  public.catalogue_page(timestamptz, uuid, integer, uuid, timestamptz),
  public.regular_maal(uuid, integer),
  public.reorder_preview(uuid),
  public.share_product(uuid, uuid),
  public.bill_payload(uuid),
  public.dashboard_summary()
  from public, anon;

grant execute on function
  public.search_all(text, integer),
  public.catalogue_page(timestamptz, uuid, integer, uuid, timestamptz),
  public.regular_maal(uuid, integer),
  public.reorder_preview(uuid),
  public.share_product(uuid, uuid),
  public.bill_payload(uuid),
  public.dashboard_summary()
  to authenticated;

-- Invoker RPCs call these helpers as the API role.
grant execute on function app.resolve_rate(uuid, uuid, uuid), app.primary_thumb(uuid, uuid) to authenticated;
