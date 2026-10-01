-- Orders, payments, the append-only ledger (Hisaab), bills.
-- None of these tables accept direct client writes: every change goes
-- through a SECURITY DEFINER RPC (next migration) that authorises,
-- validates, recomputes totals server-side and runs in one transaction.

create type public.order_status as enum ('confirmed', 'processing', 'ready', 'completed', 'cancelled');
create type public.payment_mode as enum ('cash', 'upi', 'bank', 'cheque');
create type public.ledger_kind as enum ('opening', 'order', 'payment', 'adjustment', 'reversal');

-- Allowed order transitions. Data, not code, so it is reviewable and testable.
create table app.order_transitions (
  from_status public.order_status not null,
  to_status public.order_status not null,
  primary key (from_status, to_status)
);
insert into app.order_transitions (from_status, to_status) values
  ('confirmed', 'processing'),
  ('confirmed', 'ready'),
  ('confirmed', 'completed'),
  ('confirmed', 'cancelled'),
  ('processing', 'ready'),
  ('processing', 'cancelled'),
  ('ready', 'completed'),
  ('ready', 'cancelled');

-- ---------------------------------------------------------------------------
-- Orders
-- ---------------------------------------------------------------------------
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id),
  order_no bigint not null check (order_no > 0),
  customer_id uuid not null,
  status public.order_status not null default 'confirmed',
  total_qty integer not null check (total_qty > 0),
  total_paise bigint not null check (total_paise > 0),
  total_weight_mg bigint check (total_weight_mg >= 0),
  note text check (length(note) <= 1000),
  reorder_of uuid,
  client_request_id uuid not null,
  cancel_reason text check (length(cancel_reason) <= 400),
  created_at timestamptz not null default now(),
  created_by uuid not null,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  unique (tenant_id, id),
  unique (tenant_id, id, customer_id),
  unique (tenant_id, order_no),
  unique (tenant_id, client_request_id),
  foreign key (tenant_id, customer_id) references public.customers (tenant_id, id),
  foreign key (tenant_id, reorder_of) references public.orders (tenant_id, id)
);
create index orders_by_customer on public.orders (tenant_id, customer_id, created_at desc, id desc);
create index orders_by_status on public.orders (tenant_id, status, created_at desc) where status in ('confirmed', 'processing', 'ready');
create index orders_recent on public.orders (tenant_id, created_at desc, id desc);

-- Line items are an immutable snapshot of what was sold, at what rate.
-- Later catalogue edits/archival never change history.
create table public.order_items (
  tenant_id uuid not null,
  order_id uuid not null,
  customer_id uuid not null,
  line_no smallint not null check (line_no between 1 and 200),
  product_id uuid not null,
  design_no text not null,
  product_name text not null,
  thumb_path text,
  rate_paise bigint not null check (rate_paise > 0),
  qty integer not null check (qty > 0 and qty <= 100000),
  amount_paise bigint not null,
  weight_mg integer check (weight_mg > 0),
  primary key (tenant_id, order_id, line_no),
  unique (tenant_id, order_id, product_id),
  foreign key (tenant_id, order_id, customer_id) references public.orders (tenant_id, id, customer_id),
  foreign key (tenant_id, product_id) references public.products (tenant_id, id),
  check (amount_paise = rate_paise * qty)
);
-- Regular Maal: what has this customer bought, most often / most recently.
create index order_items_regular on public.order_items (tenant_id, customer_id, product_id);
create index order_items_by_product on public.order_items (tenant_id, product_id);

-- ---------------------------------------------------------------------------
-- Payments
-- ---------------------------------------------------------------------------
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id),
  payment_no bigint not null check (payment_no > 0),
  customer_id uuid not null,
  order_id uuid,
  amount_paise bigint not null check (amount_paise > 0 and amount_paise <= 10000000000000),
  mode public.payment_mode not null,
  reference text check (length(reference) <= 60),
  note text check (length(note) <= 400),
  balance_before_paise bigint not null,
  balance_after_paise bigint not null,
  client_request_id uuid not null,
  received_at timestamptz not null default now(),
  created_by uuid not null,
  unique (tenant_id, id),
  unique (tenant_id, payment_no),
  unique (tenant_id, client_request_id),
  foreign key (tenant_id, customer_id) references public.customers (tenant_id, id),
  foreign key (tenant_id, order_id, customer_id) references public.orders (tenant_id, id, customer_id),
  check (balance_after_paise = balance_before_paise - amount_paise)
);
create index payments_by_customer on public.payments (tenant_id, customer_id, received_at desc);
create index payments_recent on public.payments (tenant_id, received_at desc);

-- ---------------------------------------------------------------------------
-- Ledger (Hisaab). Append-only. Positive amount = customer owes more (Baki ↑).
-- ---------------------------------------------------------------------------
create table public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  customer_id uuid not null,
  kind public.ledger_kind not null,
  amount_paise bigint not null check (amount_paise <> 0 and abs(amount_paise) <= 10000000000000),
  balance_after_paise bigint not null,
  order_id uuid,
  payment_id uuid,
  reverses_entry_id uuid,
  note text check (length(note) <= 400),
  client_request_id uuid,
  created_at timestamptz not null default now(),
  created_by uuid not null,
  unique (tenant_id, id),
  foreign key (tenant_id, customer_id) references public.customers (tenant_id, id),
  foreign key (tenant_id, order_id, customer_id) references public.orders (tenant_id, id, customer_id),
  foreign key (tenant_id, payment_id) references public.payments (tenant_id, id),
  foreign key (tenant_id, reverses_entry_id) references public.ledger_entries (tenant_id, id),
  check (kind <> 'order' or (order_id is not null and amount_paise > 0)),
  check (kind <> 'payment' or (payment_id is not null and amount_paise < 0)),
  check (kind <> 'reversal' or reverses_entry_id is not null),
  check (kind not in ('adjustment', 'opening') or (order_id is null and payment_id is null))
);
create index ledger_by_customer on public.ledger_entries (tenant_id, customer_id, created_at desc, id desc);
create unique index ledger_one_order_entry on public.ledger_entries (tenant_id, order_id) where kind = 'order';
create unique index ledger_one_payment_entry on public.ledger_entries (tenant_id, payment_id) where kind = 'payment';
create unique index ledger_one_reversal on public.ledger_entries (tenant_id, reverses_entry_id) where kind = 'reversal';
create unique index ledger_one_opening on public.ledger_entries (tenant_id, customer_id) where kind = 'opening';
create unique index ledger_request_key on public.ledger_entries (tenant_id, client_request_id) where client_request_id is not null;

create or replace function app.forbid_mutation() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = 'P0001', message = 'immutable_record';
end
$$;
create trigger ledger_entries_immutable before update or delete on public.ledger_entries
  for each row execute function app.forbid_mutation();
create trigger order_items_immutable before update or delete on public.order_items
  for each row execute function app.forbid_mutation();
create trigger payments_immutable before update or delete on public.payments
  for each row execute function app.forbid_mutation();

-- The ONLY way balances change: insert a ledger row and move the balance in
-- the same transaction, under the customer's balance row lock.
create or replace function app.post_ledger(
  p_tenant uuid,
  p_customer uuid,
  p_kind public.ledger_kind,
  p_amount bigint,
  p_order uuid default null,
  p_payment uuid default null,
  p_reverses uuid default null,
  p_note text default null,
  p_request uuid default null
) returns public.ledger_entries
language plpgsql
set search_path = ''
as $$
declare
  v_balance bigint;
  v_entry public.ledger_entries;
begin
  update public.customer_balances
     set balance_paise = balance_paise + p_amount,
         last_activity_at = now()
   where tenant_id = p_tenant and customer_id = p_customer
  returning balance_paise into v_balance;

  if not found then
    perform app.fail('customer_not_found');
  end if;

  insert into public.ledger_entries (tenant_id, customer_id, kind, amount_paise, balance_after_paise,
    order_id, payment_id, reverses_entry_id, note, client_request_id, created_by)
  values (p_tenant, p_customer, p_kind, p_amount, v_balance,
    p_order, p_payment, p_reverses, p_note, p_request, auth.uid())
  returning * into v_entry;

  return v_entry;
end
$$;

-- ---------------------------------------------------------------------------
-- Bills. One bill per order; header snapshot at issue time. Line items are
-- the order's immutable order_items, so no bill_items copy is needed.
-- ---------------------------------------------------------------------------
create table public.bills (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id),
  bill_no bigint not null check (bill_no > 0),
  order_id uuid not null,
  customer_id uuid not null,
  customer_name text not null,
  customer_phone text,
  business_snapshot jsonb not null,
  total_qty integer not null check (total_qty > 0),
  total_paise bigint not null check (total_paise > 0),
  total_weight_mg bigint,
  paid_paise bigint not null default 0 check (paid_paise >= 0),
  balance_after_paise bigint not null,
  pdf_path text,
  issued_at timestamptz not null default now(),
  issued_by uuid not null,
  unique (tenant_id, id),
  unique (tenant_id, bill_no),
  unique (tenant_id, order_id),
  foreign key (tenant_id, order_id, customer_id) references public.orders (tenant_id, id, customer_id),
  check (pdf_path is null or pdf_path like tenant_id::text || '/%')
);
create index bills_recent on public.bills (tenant_id, issued_at desc);

-- ---------------------------------------------------------------------------
-- RLS: read-only to clients, scoped by tenant + permission.
-- ---------------------------------------------------------------------------
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.payments enable row level security;
alter table public.ledger_entries enable row level security;
alter table public.bills enable row level security;

create policy orders_select on public.orders for select to authenticated
  using (tenant_id = (select app.current_tenant_id()));
create policy order_items_select on public.order_items for select to authenticated
  using (tenant_id = (select app.current_tenant_id()));
-- Bills carry the customer's Baki, so they need bills.issue or hisaab.view.
create policy bills_select on public.bills for select to authenticated
  using (
    tenant_id = (select app.current_tenant_id())
    and ((select app.has_permission('bills.issue')) or (select app.has_permission('hisaab.view')))
  );
create policy payments_select on public.payments for select to authenticated
  using (
    tenant_id = (select app.current_tenant_id())
    and ((select app.has_permission('hisaab.view')) or (select app.has_permission('payments.record')))
  );
create policy ledger_select on public.ledger_entries for select to authenticated
  using (tenant_id = (select app.current_tenant_id()) and (select app.has_permission('hisaab.view')));

revoke all on public.orders, public.order_items, public.payments, public.ledger_entries, public.bills
  from anon, authenticated;
-- Idempotency keys (client_request_id) are server-internal: they are never
-- readable by clients, so nobody can replay another member's request.
-- Consequence: clients must select explicit columns (PostgREST `select=*`
-- on these tables is denied) — which the API contract requires anyway.
grant select on public.order_items, public.bills to authenticated;
grant select (id, tenant_id, order_no, customer_id, status, total_qty, total_paise, total_weight_mg, note,
  reorder_of, cancel_reason, created_at, created_by, updated_at, updated_by)
  on public.orders to authenticated;
grant select (id, tenant_id, payment_no, customer_id, order_id, amount_paise, mode, reference, note,
  balance_before_paise, balance_after_paise, received_at, created_by)
  on public.payments to authenticated;
grant select (id, tenant_id, customer_id, kind, amount_paise, balance_after_paise, order_id, payment_id,
  reverses_entry_id, note, created_at, created_by)
  on public.ledger_entries to authenticated;
revoke all on app.order_transitions from public;
