-- Server-authoritative business operations. Each RPC:
--   1. resolves the tenant from the verified session (never a parameter),
--   2. checks the caller's permission,
--   3. is idempotent on client_request_id (retries return the first result),
--   4. validates and recomputes everything (client totals are never accepted),
--   5. writes ledger + balance + audit in ONE transaction.
-- Error `message` values are stable codes documented in docs/architecture/api.md.

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------
create or replace function app.idempotency_lock(p_tenant uuid, p_scope text, p_request uuid) returns void
language plpgsql
set search_path = ''
as $$
begin
  if p_request is null then
    perform app.fail('invalid_request', jsonb_build_object('field', 'client_request_id'));
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_scope || ':' || p_tenant::text || ':' || p_request::text, 0));
end
$$;

-- Effective selling rate for a customer: customer override, else product rate.
create or replace function app.resolve_rate(p_tenant uuid, p_customer uuid, p_product uuid) returns bigint
language sql stable
set search_path = ''
as $$
  select coalesce(
    (select r.rate_paise from public.customer_product_rates r
      where r.tenant_id = p_tenant and r.customer_id = p_customer and r.product_id = p_product),
    (select p.rate_paise from public.products p
      where p.tenant_id = p_tenant and p.id = p_product)
  )
$$;

create or replace function app.primary_thumb(p_tenant uuid, p_product uuid) returns text
language sql stable
set search_path = ''
as $$
  select m.thumb_path
    from public.product_media m
   where m.tenant_id = p_tenant and m.product_id = p_product
     and m.kind = 'image' and m.status = 'ready' and m.archived_at is null
   order by m.sort_order, m.created_at
   limit 1
$$;

create or replace function app.order_json(p_order public.orders, p_replayed boolean) returns jsonb
language sql stable
set search_path = ''
as $$
  select jsonb_build_object(
    'order_id', p_order.id,
    'order_no', p_order.order_no,
    'customer_id', p_order.customer_id,
    'status', p_order.status,
    'total_qty', p_order.total_qty,
    'total_paise', p_order.total_paise,
    'total_weight_mg', p_order.total_weight_mg,
    'created_at', p_order.created_at,
    'replayed', p_replayed
  )
$$;

create or replace function app.payment_json(p_payment public.payments, p_replayed boolean) returns jsonb
language sql stable
set search_path = ''
as $$
  select jsonb_build_object(
    'payment_id', p_payment.id,
    'payment_no', p_payment.payment_no,
    'customer_id', p_payment.customer_id,
    'amount_paise', p_payment.amount_paise,
    'mode', p_payment.mode,
    'balance_before_paise', p_payment.balance_before_paise,
    'balance_after_paise', p_payment.balance_after_paise,
    'received_at', p_payment.received_at,
    'replayed', p_replayed
  )
$$;

-- Records a payment under the customer's balance row lock so the receipt's
-- old/new Baki is exactly consistent with the ledger.
create or replace function app.record_payment_core(
  p_tenant uuid, p_customer uuid, p_amount bigint, p_mode public.payment_mode,
  p_reference text, p_note text, p_order uuid, p_request uuid
) returns public.payments
language plpgsql
set search_path = ''
as $$
declare
  v_before bigint;
  v_payment public.payments;
  v_entry public.ledger_entries;
begin
  if p_amount is null or p_amount <= 0 or p_amount > 10000000000000 then
    perform app.fail('invalid_amount');
  end if;
  if p_mode is null then
    perform app.fail('invalid_request', jsonb_build_object('field', 'mode'));
  end if;

  select b.balance_paise into v_before
    from public.customer_balances b
   where b.tenant_id = p_tenant and b.customer_id = p_customer
   for update;
  if not found then
    perform app.fail('customer_not_found');
  end if;

  insert into public.payments (tenant_id, payment_no, customer_id, order_id, amount_paise, mode,
    reference, note, balance_before_paise, balance_after_paise, client_request_id, created_by)
  values (p_tenant, app.next_number(p_tenant, 'payment'), p_customer, p_order, p_amount, p_mode,
    nullif(btrim(p_reference), ''), nullif(btrim(p_note), ''), v_before, v_before - p_amount, p_request, auth.uid())
  returning * into v_payment;

  v_entry := app.post_ledger(p_tenant, p_customer, 'payment', -p_amount, p_payment => v_payment.id);
  if v_entry.balance_after_paise <> v_payment.balance_after_paise then
    perform app.fail('internal_consistency');
  end if;

  perform app.audit(p_tenant, 'payment.recorded', 'payments', v_payment.id,
    jsonb_build_object('customer_id', p_customer, 'amount_paise', p_amount, 'mode', p_mode));
  return v_payment;
end
$$;

-- ---------------------------------------------------------------------------
-- create_order
--   p_items: [{ "product_id": uuid, "qty": int, "expected_rate_paise": int? }]
--   Duplicate product lines are merged. If expected_rate_paise is sent and the
--   server's effective rate differs, fails with `rate_changed` (detail lists
--   the current rates) so the user re-confirms — no silent repricing.
--   p_payment (optional): { "amount_paise": int, "mode": "cash"|"upi"|"bank"|"cheque",
--   "reference": text? } recorded atomically with the order.
-- ---------------------------------------------------------------------------
create or replace function public.create_order(
  p_customer_id uuid,
  p_items jsonb,
  p_client_request_id uuid,
  p_note text default null,
  p_reorder_of uuid default null,
  p_payment jsonb default null
) returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_permission('orders.create');
  v_order public.orders;
  v_customer public.customers;
  v_lines jsonb;
  v_problem jsonb;
  v_total_qty bigint;
  v_total bigint;
  v_weight bigint;
  v_payment public.payments;
  v_result jsonb;
begin
  perform app.idempotency_lock(v_tenant, 'order', p_client_request_id);

  select * into v_order from public.orders
   where tenant_id = v_tenant and client_request_id = p_client_request_id;
  if found then
    return app.order_json(v_order, true);
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    perform app.fail('order_empty');
  end if;
  if jsonb_array_length(p_items) > 200 then
    perform app.fail('order_too_large');
  end if;
  if p_note is not null and length(p_note) > 1000 then
    perform app.fail('invalid_request', jsonb_build_object('field', 'note'));
  end if;

  select * into v_customer from public.customers
   where tenant_id = v_tenant and id = p_customer_id;
  if not found then
    perform app.fail('customer_not_found');
  end if;
  if v_customer.archived_at is not null then
    perform app.fail('customer_inactive');
  end if;

  if p_reorder_of is not null and not exists (
    select 1 from public.orders where tenant_id = v_tenant and id = p_reorder_of) then
    perform app.fail('order_not_found');
  end if;

  -- Parse defensively: malformed JSON values become a clean error code.
  -- Duplicate product lines are merged (quantities summed).
  begin
    select jsonb_agg(jsonb_build_object('seq', x.seq, 'product_id', x.product_id, 'qty', x.qty,
                                        'expected_rate_paise', x.expected_rate_paise))
      into v_lines
      from (
        select min(e.ord)::integer as seq,
               (e.value ->> 'product_id')::uuid as product_id,
               sum((e.value ->> 'qty')::integer)::integer as qty,
               max((e.value ->> 'expected_rate_paise')::bigint) as expected_rate_paise
          from jsonb_array_elements(p_items) with ordinality as e(value, ord)
         group by (e.value ->> 'product_id')::uuid
      ) x;
  exception
    when invalid_text_representation or numeric_value_out_of_range
      or invalid_parameter_value or cannot_coerce then
      perform app.fail('invalid_request', jsonb_build_object('field', 'items'));
  end;

  if exists (select 1 from jsonb_to_recordset(v_lines) as l(product_id uuid, qty integer)
              where l.product_id is null or l.qty is null or l.qty < 1 or l.qty > 100000) then
    perform app.fail('invalid_quantity');
  end if;

  if exists (select 1 from jsonb_to_recordset(v_lines) as l(product_id uuid)
              where not exists (select 1 from public.products p
                                 where p.tenant_id = v_tenant and p.id = l.product_id)) then
    perform app.fail('product_not_found');
  end if;

  select jsonb_agg(jsonb_build_object('product_id', p.id, 'design_no', p.design_no)) into v_problem
    from jsonb_to_recordset(v_lines) as l(product_id uuid)
    join public.products p on p.tenant_id = v_tenant and p.id = l.product_id
   where p.status <> 'active' or not p.is_available;
  if v_problem is not null then
    perform app.fail('product_unavailable', v_problem);
  end if;

  select jsonb_agg(jsonb_build_object('product_id', l.product_id,
                                      'rate_paise', app.resolve_rate(v_tenant, p_customer_id, l.product_id)))
    into v_problem
    from jsonb_to_recordset(v_lines) as l(product_id uuid, expected_rate_paise bigint)
   where l.expected_rate_paise is not null
     and l.expected_rate_paise <> app.resolve_rate(v_tenant, p_customer_id, l.product_id);
  if v_problem is not null then
    perform app.fail('rate_changed', v_problem);
  end if;

  select sum(l.qty),
         sum(app.resolve_rate(v_tenant, p_customer_id, l.product_id) * l.qty),
         sum(p.weight_mg::bigint * l.qty)
    into v_total_qty, v_total, v_weight
    from jsonb_to_recordset(v_lines) as l(product_id uuid, qty integer)
    join public.products p on p.tenant_id = v_tenant and p.id = l.product_id;

  if v_total > 10000000000000 or v_total_qty > 2000000000 then
    perform app.fail('amount_too_large');
  end if;

  insert into public.orders (tenant_id, order_no, customer_id, total_qty, total_paise, total_weight_mg,
    note, reorder_of, client_request_id, created_by)
  values (v_tenant, app.next_number(v_tenant, 'order'), p_customer_id, v_total_qty, v_total, v_weight,
    nullif(btrim(p_note), ''), p_reorder_of, p_client_request_id, auth.uid())
  returning * into v_order;

  insert into public.order_items (tenant_id, order_id, customer_id, line_no, product_id, design_no,
    product_name, thumb_path, rate_paise, qty, amount_paise, weight_mg)
  select v_tenant, v_order.id, p_customer_id,
         row_number() over (order by l.seq),
         p.id, p.design_no, p.name, app.primary_thumb(v_tenant, p.id),
         r.rate, l.qty, r.rate * l.qty, p.weight_mg
    from jsonb_to_recordset(v_lines) as l(seq integer, product_id uuid, qty integer)
    join public.products p on p.tenant_id = v_tenant and p.id = l.product_id
    cross join lateral (select app.resolve_rate(v_tenant, p_customer_id, l.product_id) as rate) r;

  perform app.post_ledger(v_tenant, p_customer_id, 'order', v_total, p_order => v_order.id);
  perform app.audit(v_tenant, 'order.created', 'orders', v_order.id,
    jsonb_build_object('order_no', v_order.order_no, 'total_paise', v_total, 'reorder_of', p_reorder_of));

  v_result := app.order_json(v_order, false);

  if p_payment is not null and p_payment <> 'null'::jsonb then
    begin
      v_payment := app.record_payment_core(
        v_tenant, p_customer_id,
        (p_payment ->> 'amount_paise')::bigint,
        (p_payment ->> 'mode')::public.payment_mode,
        p_payment ->> 'reference', null, v_order.id,
        -- Deterministic: the payment shares the order's idempotency.
        md5('payment:' || p_client_request_id::text)::uuid);
    exception
      when invalid_text_representation or numeric_value_out_of_range then
        perform app.fail('invalid_request', jsonb_build_object('field', 'payment'));
    end;
    v_result := v_result || jsonb_build_object('payment', app.payment_json(v_payment, false));
  end if;

  return v_result;
end
$$;

-- ---------------------------------------------------------------------------
-- record_payment
-- ---------------------------------------------------------------------------
create or replace function public.record_payment(
  p_customer_id uuid,
  p_amount_paise bigint,
  p_mode public.payment_mode,
  p_client_request_id uuid,
  p_reference text default null,
  p_note text default null,
  p_order_id uuid default null
) returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_permission('payments.record');
  v_payment public.payments;
begin
  perform app.idempotency_lock(v_tenant, 'payment', p_client_request_id);

  select * into v_payment from public.payments
   where tenant_id = v_tenant and client_request_id = p_client_request_id;
  if found then
    return app.payment_json(v_payment, true);
  end if;

  if not exists (select 1 from public.customers where tenant_id = v_tenant and id = p_customer_id) then
    perform app.fail('customer_not_found');
  end if;
  if p_order_id is not null and not exists (
    select 1 from public.orders where tenant_id = v_tenant and id = p_order_id and customer_id = p_customer_id) then
    perform app.fail('order_not_found');
  end if;
  if length(p_reference) > 60 or length(p_note) > 400 then
    perform app.fail('invalid_request', jsonb_build_object('field', 'reference'));
  end if;

  v_payment := app.record_payment_core(v_tenant, p_customer_id, p_amount_paise, p_mode,
    p_reference, p_note, p_order_id, p_client_request_id);
  return app.payment_json(v_payment, false);
end
$$;

-- ---------------------------------------------------------------------------
-- record_adjustment: opening balance (once per customer) or a signed
-- correction (return, discount, write-off). A note is mandatory for
-- adjustments so the Hisaab always explains itself.
-- ---------------------------------------------------------------------------
create or replace function public.record_adjustment(
  p_customer_id uuid,
  p_kind public.ledger_kind,
  p_amount_paise bigint,
  p_client_request_id uuid,
  p_note text default null
) returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_permission('hisaab.adjust');
  v_entry public.ledger_entries;
begin
  perform app.idempotency_lock(v_tenant, 'ledger', p_client_request_id);

  select * into v_entry from public.ledger_entries
   where tenant_id = v_tenant and client_request_id = p_client_request_id;
  if found then
    return jsonb_build_object('entry_id', v_entry.id, 'balance_after_paise', v_entry.balance_after_paise, 'replayed', true);
  end if;

  if p_kind not in ('opening', 'adjustment') then
    perform app.fail('invalid_request', jsonb_build_object('field', 'kind'));
  end if;
  if p_amount_paise is null or p_amount_paise = 0 or abs(p_amount_paise) > 10000000000000 then
    perform app.fail('invalid_amount');
  end if;
  if p_kind = 'adjustment' and (p_note is null or length(btrim(p_note)) = 0) then
    perform app.fail('note_required');
  end if;
  if not exists (select 1 from public.customers where tenant_id = v_tenant and id = p_customer_id) then
    perform app.fail('customer_not_found');
  end if;
  if p_kind = 'opening' and exists (
    select 1 from public.ledger_entries
     where tenant_id = v_tenant and customer_id = p_customer_id and kind = 'opening') then
    perform app.fail('opening_exists');
  end if;

  perform 1 from public.customer_balances
   where tenant_id = v_tenant and customer_id = p_customer_id for update;

  v_entry := app.post_ledger(v_tenant, p_customer_id, p_kind, p_amount_paise,
    p_note => nullif(btrim(p_note), ''), p_request => p_client_request_id);
  perform app.audit(v_tenant, 'ledger.' || p_kind::text, 'ledger_entries', v_entry.id,
    jsonb_build_object('customer_id', p_customer_id, 'amount_paise', p_amount_paise));
  return jsonb_build_object('entry_id', v_entry.id, 'balance_after_paise', v_entry.balance_after_paise, 'replayed', false);
end
$$;

-- ---------------------------------------------------------------------------
-- Order status changes
-- ---------------------------------------------------------------------------
create or replace function public.transition_order(p_order_id uuid, p_to public.order_status)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_permission('orders.manage');
  v_order public.orders;
begin
  if p_to = 'cancelled' then
    perform app.fail('invalid_request', jsonb_build_object('hint', 'use cancel_order'));
  end if;

  select * into v_order from public.orders where tenant_id = v_tenant and id = p_order_id for update;
  if not found then
    perform app.fail('order_not_found');
  end if;
  if v_order.status = p_to then
    return app.order_json(v_order, true);
  end if;
  if not exists (select 1 from app.order_transitions where from_status = v_order.status and to_status = p_to) then
    perform app.fail('invalid_transition', jsonb_build_object('from', v_order.status, 'to', p_to));
  end if;

  update public.orders set status = p_to, updated_at = now(), updated_by = auth.uid()
   where tenant_id = v_tenant and id = p_order_id
  returning * into v_order;
  perform app.audit(v_tenant, 'order.status', 'orders', v_order.id, jsonb_build_object('to', p_to));
  return app.order_json(v_order, false);
end
$$;

-- Cancelling reverses the order's ledger effect. Payments are untouched: any
-- money already received stays as customer credit (visible in Hisaab).
create or replace function public.cancel_order(p_order_id uuid, p_reason text default null)
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_permission('orders.manage');
  v_order public.orders;
  v_entry public.ledger_entries;
begin
  select * into v_order from public.orders where tenant_id = v_tenant and id = p_order_id for update;
  if not found then
    perform app.fail('order_not_found');
  end if;
  if v_order.status = 'cancelled' then
    return app.order_json(v_order, true);
  end if;
  if not exists (select 1 from app.order_transitions where from_status = v_order.status and to_status = 'cancelled') then
    perform app.fail('invalid_transition', jsonb_build_object('from', v_order.status, 'to', 'cancelled'));
  end if;
  if length(p_reason) > 400 then
    perform app.fail('invalid_request', jsonb_build_object('field', 'reason'));
  end if;

  select * into v_entry from public.ledger_entries
   where tenant_id = v_tenant and order_id = p_order_id and kind = 'order';

  update public.orders
     set status = 'cancelled', cancel_reason = nullif(btrim(p_reason), ''), updated_at = now(), updated_by = auth.uid()
   where tenant_id = v_tenant and id = p_order_id
  returning * into v_order;

  perform app.post_ledger(v_tenant, v_order.customer_id, 'reversal', -v_entry.amount_paise,
    p_order => v_order.id, p_reverses => v_entry.id, p_note => 'order_cancelled');
  perform app.audit(v_tenant, 'order.cancelled', 'orders', v_order.id, jsonb_build_object('reason', p_reason));
  return app.order_json(v_order, false);
end
$$;

-- ---------------------------------------------------------------------------
-- Bills: issued from the authoritative order; one bill per order.
-- ---------------------------------------------------------------------------
create or replace function public.issue_bill(p_order_id uuid) returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_permission('bills.issue');
  v_order public.orders;
  v_bill public.bills;
  v_customer public.customers;
  v_business jsonb;
  v_paid bigint;
  v_balance bigint;
  v_replayed boolean := true;
begin
  select * into v_order from public.orders where tenant_id = v_tenant and id = p_order_id for update;
  if not found then
    perform app.fail('order_not_found');
  end if;

  select * into v_bill from public.bills where tenant_id = v_tenant and order_id = p_order_id;
  if not found then
    if v_order.status = 'cancelled' then
      perform app.fail('order_cancelled');
    end if;
    v_replayed := false;

    select * into v_customer from public.customers where tenant_id = v_tenant and id = v_order.customer_id;
    select jsonb_build_object('business_name', b.business_name, 'phone', b.phone,
             'whatsapp_phone', b.whatsapp_phone, 'address', b.address, 'gstin', b.gstin,
             'bill_footer', b.bill_footer, 'logo_path', b.logo_path, 'watermark_enabled', b.watermark_enabled)
      into v_business
      from public.business_profiles b where b.tenant_id = v_tenant;
    select coalesce(sum(amount_paise), 0) into v_paid
      from public.payments where tenant_id = v_tenant and order_id = p_order_id;
    select balance_paise into v_balance
      from public.customer_balances where tenant_id = v_tenant and customer_id = v_order.customer_id;

    insert into public.bills (tenant_id, bill_no, order_id, customer_id, customer_name, customer_phone,
      business_snapshot, total_qty, total_paise, total_weight_mg, paid_paise, balance_after_paise, issued_by)
    values (v_tenant, app.next_number(v_tenant, 'bill'), v_order.id, v_order.customer_id, v_customer.name,
      coalesce(v_customer.whatsapp_phone, v_customer.phone), coalesce(v_business, '{}'::jsonb),
      v_order.total_qty, v_order.total_paise, v_order.total_weight_mg, v_paid, v_balance, auth.uid())
    returning * into v_bill;
    perform app.audit(v_tenant, 'bill.issued', 'bills', v_bill.id, jsonb_build_object('bill_no', v_bill.bill_no));
  end if;

  return jsonb_build_object('bill_id', v_bill.id, 'bill_no', v_bill.bill_no, 'replayed', v_replayed);
end
$$;

-- ---------------------------------------------------------------------------
-- Staff management (owner only). Account creation itself needs the Auth
-- admin API and is done by a service-role Edge Function (later increment)
-- which then calls admin_add_member().
-- ---------------------------------------------------------------------------
create or replace function public.set_member_permissions(p_user_id uuid, p_permissions public.app_permission[])
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_owner();
  v_role public.member_role;
begin
  select role into v_role from public.tenant_members where tenant_id = v_tenant and user_id = p_user_id;
  if not found then
    perform app.fail('member_not_found');
  end if;
  if v_role = 'owner' then
    perform app.fail('invalid_request', jsonb_build_object('hint', 'owner has all permissions'));
  end if;

  delete from public.member_permissions
   where tenant_id = v_tenant and user_id = p_user_id
     and permission <> all (coalesce(p_permissions, '{}'));
  insert into public.member_permissions (tenant_id, user_id, permission, granted_by)
  select v_tenant, p_user_id, p, auth.uid() from unnest(coalesce(p_permissions, '{}')) as p
  on conflict do nothing;
end
$$;

create or replace function public.set_member_active(p_user_id uuid, p_active boolean) returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_owner();
begin
  update public.tenant_members set is_active = p_active, updated_at = now(), updated_by = auth.uid()
   where tenant_id = v_tenant and user_id = p_user_id and role = 'staff';
  if not found then
    perform app.fail('member_not_found');
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- Service-role provisioning (Edge Function / ops scripts only).
-- ---------------------------------------------------------------------------
create or replace function public.admin_create_tenant(
  p_slug text, p_business_name text, p_owner_id uuid, p_username text, p_display_name text
) returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tenant uuid;
begin
  insert into public.tenants (slug) values (p_slug) returning id into v_tenant;
  insert into public.business_profiles (tenant_id, business_name) values (v_tenant, p_business_name);
  insert into public.app_users (id, username, display_name) values (p_owner_id, lower(p_username), p_display_name);
  insert into public.tenant_members (tenant_id, user_id, role) values (v_tenant, p_owner_id, 'owner');
  insert into public.tenant_counters (tenant_id, counter)
  values (v_tenant, 'order'), (v_tenant, 'payment'), (v_tenant, 'bill');
  return v_tenant;
end
$$;

create or replace function public.admin_add_member(
  p_tenant_id uuid, p_user_id uuid, p_username text, p_display_name text,
  p_role public.member_role, p_permissions public.app_permission[] default '{}'
) returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.app_users (id, username, display_name) values (p_user_id, lower(p_username), p_display_name);
  insert into public.tenant_members (tenant_id, user_id, role) values (p_tenant_id, p_user_id, p_role);
  insert into public.member_permissions (tenant_id, user_id, permission)
  select p_tenant_id, p_user_id, p from unnest(p_permissions) as p;
end
$$;

-- Function privileges: deny by default, then grant precisely.
revoke all on function
  public.create_order(uuid, jsonb, uuid, text, uuid, jsonb),
  public.record_payment(uuid, bigint, public.payment_mode, uuid, text, text, uuid),
  public.record_adjustment(uuid, public.ledger_kind, bigint, uuid, text),
  public.transition_order(uuid, public.order_status),
  public.cancel_order(uuid, text),
  public.issue_bill(uuid),
  public.set_member_permissions(uuid, public.app_permission[]),
  public.set_member_active(uuid, boolean),
  public.admin_create_tenant(text, text, uuid, text, text),
  public.admin_add_member(uuid, uuid, text, text, public.member_role, public.app_permission[])
  from public, anon, authenticated;

grant execute on function
  public.create_order(uuid, jsonb, uuid, text, uuid, jsonb),
  public.record_payment(uuid, bigint, public.payment_mode, uuid, text, text, uuid),
  public.record_adjustment(uuid, public.ledger_kind, bigint, uuid, text),
  public.transition_order(uuid, public.order_status),
  public.cancel_order(uuid, text),
  public.issue_bill(uuid),
  public.set_member_permissions(uuid, public.app_permission[]),
  public.set_member_active(uuid, boolean)
  to authenticated;

grant execute on function
  public.admin_create_tenant(text, text, uuid, text, text),
  public.admin_add_member(uuid, uuid, text, text, public.member_role, public.app_permission[])
  to service_role;

revoke all on all functions in schema app from public;
-- Called from triggers that run as the API role.
grant execute on function app.fail(text, jsonb) to authenticated;
