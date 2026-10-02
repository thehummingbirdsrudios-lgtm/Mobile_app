-- Staff accounts for the `staff-admin` Edge Function.
--
-- Creating a login needs the Auth admin API, so an Edge Function holding the
-- service role does it. The function first verifies the caller's JWT, then
-- calls the functions below as service_role with the caller's user id as
-- p_actor. The tenant is ALWAYS derived here from the actor's active owner
-- membership — never taken from the request — so a forged body cannot reach
-- another business, and a deactivated owner or suspended business is refused.

-- The business the actor owns, or NULL (not an active owner of an active tenant).
create or replace function app.owner_tenant_of(p_actor uuid) returns uuid
language sql stable security definer
set search_path = ''
as $$
  select m.tenant_id
    from public.tenant_members m
    join public.tenants t on t.id = m.tenant_id
   where m.user_id = p_actor and m.role = 'owner' and m.is_active and t.status = 'active'
$$;

-- For the rest of this transaction auth.uid() returns the actor, so rows the
-- audit triggers write are attributed to the owner who acted (not "system").
create or replace function app.act_as(p_actor uuid) returns void
language sql
set search_path = ''
as $$
  select set_config('request.jwt.claims', jsonb_build_object('sub', p_actor, 'role', 'service_role')::text, true);
$$;

create or replace function app.require_owner_actor(p_actor uuid) returns uuid
language plpgsql stable
set search_path = ''
as $$
declare
  v_tenant uuid := app.owner_tenant_of(p_actor);
begin
  if v_tenant is null then
    perform app.fail('permission_denied');
  end if;
  return v_tenant;
end
$$;

-- Adds an already-created auth user as STAFF of the actor's business.
create or replace function public.staff_admin_create(
  p_actor uuid, p_user_id uuid, p_username text, p_display_name text, p_permissions public.app_permission[]
) returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_owner_actor(p_actor);
  v_username text := lower(btrim(coalesce(p_username, '')));
  v_name text := btrim(coalesce(p_display_name, ''));
begin
  if v_username !~ '^[a-z0-9][a-z0-9._]{2,31}$' then
    perform app.fail('invalid_request', jsonb_build_object('field', 'username'));
  end if;
  if length(v_name) not between 1 and 80 then
    perform app.fail('invalid_request', jsonb_build_object('field', 'display_name'));
  end if;
  if exists (select 1 from public.app_users u where lower(u.username) = v_username) then
    perform app.fail('username_taken');
  end if;

  perform app.act_as(p_actor);
  insert into public.app_users (id, username, display_name) values (p_user_id, v_username, v_name);
  insert into public.tenant_members (tenant_id, user_id, role, updated_by)
  values (v_tenant, p_user_id, 'staff', p_actor);
  insert into public.member_permissions (tenant_id, user_id, permission, granted_by)
  select distinct v_tenant, p_user_id, p, p_actor from unnest(coalesce(p_permissions, '{}')) as p;
  perform app.audit(v_tenant, 'staff.created', 'tenant_members', p_user_id, jsonb_build_object('username', v_username));

  return jsonb_build_object('user_id', p_user_id);
end
$$;

-- Authorises a password reset: the target must be STAFF of the actor's business.
create or replace function public.staff_admin_check_target(p_actor uuid, p_user_id uuid) returns void
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_owner_actor(p_actor);
begin
  if not exists (
    select 1 from public.tenant_members m
     where m.tenant_id = v_tenant and m.user_id = p_user_id and m.role = 'staff'
  ) then
    perform app.fail('member_not_found');
  end if;
end
$$;

-- Records a completed password reset (called only after Auth accepted it).
-- Never stores the password or anything derived from it.
create or replace function public.staff_admin_record_password_reset(p_actor uuid, p_user_id uuid) returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  v_tenant uuid := app.require_owner_actor(p_actor);
begin
  perform public.staff_admin_check_target(p_actor, p_user_id);
  perform app.act_as(p_actor);
  perform app.audit(v_tenant, 'staff.password_reset', 'tenant_members', p_user_id);
end
$$;

revoke all on function
  app.owner_tenant_of(uuid),
  app.act_as(uuid),
  app.require_owner_actor(uuid)
  from public;

revoke all on function
  public.staff_admin_create(uuid, uuid, text, text, public.app_permission[]),
  public.staff_admin_check_target(uuid, uuid),
  public.staff_admin_record_password_reset(uuid, uuid)
  from public, anon, authenticated;

grant execute on function
  public.staff_admin_create(uuid, uuid, text, text, public.app_permission[]),
  public.staff_admin_check_target(uuid, uuid),
  public.staff_admin_record_password_reset(uuid, uuid)
  to service_role;
