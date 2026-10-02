-- Audit log the owner can read.
--
-- 1. Row deletes now record what was removed (e.g. which permission was
--    taken away); previously a DELETE stored an empty change set.
-- 2. audit_page() also returns a short `subject` (design no., customer name,
--    staff name, order/bill/payment number) resolved inside the caller's
--    tenant, so the activity screen can say WHAT changed, not only that
--    something did.

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
  if tg_op = 'DELETE' then
    select coalesce(jsonb_object_agg(
             o.key,
             case when v_redact then to_jsonb('changed'::text) else jsonb_build_object('from', o.value, 'to', null) end),
           '{}'::jsonb)
      into v_changes
      from jsonb_each(v_old) o
     where o.key not in ('updated_at', 'updated_by', 'created_at', 'created_by', 'tenant_id');
  else
    select coalesce(jsonb_object_agg(
             n.key,
             case when v_redact then to_jsonb('changed'::text)
                  else jsonb_build_object('from', v_old -> n.key, 'to', n.value) end), '{}'::jsonb)
      into v_changes
      from jsonb_each(v_new) n
     where n.key not in ('updated_at', 'updated_by', 'created_at', 'created_by', 'tenant_id')
       and (v_old is null or (v_old -> n.key) is distinct from n.value);
  end if;

  if tg_op = 'UPDATE' and v_changes = '{}'::jsonb then
    return new;
  end if;

  v_entity_id := coalesce(v_row ->> 'id', v_row ->> 'product_id', v_row ->> 'user_id')::uuid;

  perform app.audit((v_row ->> 'tenant_id')::uuid, lower(tg_op), tg_table_name, v_entity_id, v_changes);
  return coalesce(new, old);
end
$$;

drop function public.audit_page(bigint, integer);

create function public.audit_page(p_before_id bigint default null, p_limit integer default 50)
returns table (
  id bigint, action text, entity text, entity_id uuid, data jsonb, actor_name text, created_at timestamptz, subject text
)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_owner();
begin
  return query
  select a.id, a.action, a.entity, a.entity_id, a.data, u.display_name, a.created_at,
         -- Every lookup is pinned to the caller's tenant (and to a.tenant_id).
         case
           when a.entity in ('products', 'product_private', 'customer_product_rates') then
             (select p.design_no || ' · ' || p.name from public.products p
               where p.tenant_id = v_tenant and p.id = a.entity_id)
           when a.entity = 'customers' then
             (select c.name from public.customers c where c.tenant_id = v_tenant and c.id = a.entity_id)
           when a.entity in ('tenant_members', 'member_permissions') then
             (select mu.display_name from public.tenant_members m
                join public.app_users mu on mu.id = m.user_id
               where m.tenant_id = v_tenant and m.user_id = a.entity_id)
           when a.entity = 'orders' then
             (select '#' || o.order_no from public.orders o where o.tenant_id = v_tenant and o.id = a.entity_id)
           when a.entity = 'bills' then
             (select '#' || b.bill_no from public.bills b where b.tenant_id = v_tenant and b.id = a.entity_id)
           when a.entity = 'payments' then
             (select '#' || pay.payment_no || ' · ' || c.name from public.payments pay
                join public.customers c on c.tenant_id = pay.tenant_id and c.id = pay.customer_id
               where pay.tenant_id = v_tenant and pay.id = a.entity_id)
           when a.entity = 'ledger_entries' then
             (select c.name from public.ledger_entries l
                join public.customers c on c.tenant_id = l.tenant_id and c.id = l.customer_id
               where l.tenant_id = v_tenant and l.id = a.entity_id)
         end
    from public.audit_logs a
    left join public.app_users u on u.id = a.actor_id
   where a.tenant_id = v_tenant and (p_before_id is null or a.id < p_before_id)
   order by a.id desc
   limit least(greatest(coalesce(p_limit, 50), 1), 200);
end
$$;

revoke all on function public.audit_page(bigint, integer) from public, anon;
grant execute on function public.audit_page(bigint, integer) to authenticated;
