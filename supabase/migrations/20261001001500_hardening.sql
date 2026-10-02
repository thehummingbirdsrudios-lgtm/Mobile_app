-- Hardening.
--
-- 1. Storage: the `share` bucket is closed to app users. The app shares
--    files straight from the device and never uploads there; the old policy
--    let any member read, overwrite or delete every share object (KI-012).
-- 2. Storage: full-resolution photo ORIGINALS are readable only by the owner
--    and members who manage the catalogue. Everyone else uses the
--    catalogue/share/thumb derivatives (the app never reads originals).
-- 3. Platform settings: a minimum supported app version (the app blocks
--    older builds) and a maintenance switch that pauses business writes for
--    app users while reads keep working. Operators (service role) and
--    migrations are not affected.

-- ---------------------------------------------------------------------------
-- Storage policies (replace the 20261001000700 set)
-- ---------------------------------------------------------------------------
drop policy vepari_objects_select on storage.objects;
drop policy vepari_objects_insert on storage.objects;
drop policy vepari_objects_update on storage.objects;
drop policy vepari_objects_delete on storage.objects;

create or replace function app.is_photo_original(p_name text) returns boolean
language sql immutable
set search_path = ''
as $$
  select p_name ~ '/original\.[A-Za-z0-9]+$'
$$;
grant execute on function app.is_photo_original(text) to authenticated;

create policy vepari_objects_select on storage.objects for select to authenticated
  using (
    app.object_in_my_tenant(name)
    and (
      (bucket_id = 'product-media'
        and (not app.is_photo_original(name) or app.has_permission('catalogue.manage')))
      or bucket_id in ('remarks', 'branding')
      or (bucket_id = 'bills' and (app.has_permission('bills.issue') or app.has_permission('hisaab.view')))
    )
  );

create policy vepari_objects_insert on storage.objects for insert to authenticated
  with check (
    app.object_in_my_tenant(name)
    and (
      (bucket_id = 'product-media' and app.has_permission('catalogue.manage'))
      or bucket_id = 'remarks'
      or (bucket_id = 'bills' and app.has_permission('bills.issue'))
      or (bucket_id = 'branding' and app.is_owner())
    )
  );

-- Overwrites only for regenerable files; originals are write-once. WITH
-- CHECK repeats the bucket rules so an update can never MOVE an object into
-- another bucket and bypass its insert rules.
create policy vepari_objects_update on storage.objects for update to authenticated
  using (
    app.object_in_my_tenant(name)
    and ((bucket_id = 'bills' and app.has_permission('bills.issue')) or (bucket_id = 'branding' and app.is_owner()))
  )
  with check (
    app.object_in_my_tenant(name)
    and ((bucket_id = 'bills' and app.has_permission('bills.issue')) or (bucket_id = 'branding' and app.is_owner()))
  );

-- Deletes: only the owner's own branding (old logos).
create policy vepari_objects_delete on storage.objects for delete to authenticated
  using (app.object_in_my_tenant(name) and bucket_id = 'branding' and app.is_owner());

-- ---------------------------------------------------------------------------
-- Platform settings (one row; operators change it with the service role)
-- ---------------------------------------------------------------------------
create table public.platform_settings (
  id smallint primary key default 1 check (id = 1),
  min_app_version text not null default '0.0.0' check (min_app_version ~ '^[0-9]+\.[0-9]+\.[0-9]+$'),
  maintenance boolean not null default false,
  updated_at timestamptz not null default now()
);
insert into public.platform_settings default values;
alter table public.platform_settings enable row level security;
revoke all on public.platform_settings from anon, authenticated;

-- What a client needs before anything else (callable before sign-in).
create or replace function public.app_status() returns jsonb
language sql stable security definer
set search_path = ''
as $$
  select jsonb_build_object('min_app_version', s.min_app_version, 'maintenance', s.maintenance)
    from public.platform_settings s where s.id = 1
$$;
revoke all on function public.app_status() from public;
grant execute on function public.app_status() to anon, authenticated;

-- Statement-level guard: in maintenance, app users cannot change business
-- data (RPC writes included — they run under the caller's JWT claims).
create or replace function app.forbid_in_maintenance() returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  if coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role', '') in ('authenticated', 'anon')
     and exists (select 1 from public.platform_settings s where s.id = 1 and s.maintenance) then
    perform app.fail('maintenance');
  end if;
  return null;
end
$$;
revoke all on function app.forbid_in_maintenance() from public;

do $$
declare
  t text;
begin
  foreach t in array array['customers', 'customer_product_rates', 'products', 'product_private', 'product_media',
                           'categories', 'orders', 'order_items', 'payments', 'ledger_entries', 'bills', 'remarks',
                           'business_profiles', 'tenant_members', 'member_permissions']
  loop
    execute format(
      'create trigger %I before insert or update or delete on public.%I for each statement execute function app.forbid_in_maintenance()',
      t || '_maintenance', t);
  end loop;
end
$$;
