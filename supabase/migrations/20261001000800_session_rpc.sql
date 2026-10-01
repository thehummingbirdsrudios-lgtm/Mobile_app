-- current_session(): everything the client needs after login, in one
-- server-authoritative call. Returns NULL when the caller has no active
-- membership in an active tenant (disabled staff, suspended tenant, or an
-- auth user that was never provisioned) — the client then signs out.

create or replace function public.current_session() returns jsonb
language sql stable security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'user_id', m.user_id,
    'tenant_id', m.tenant_id,
    'username', u.username,
    'display_name', u.display_name,
    'role', m.role,
    'permissions', coalesce((
      select jsonb_agg(p.permission order by p.permission)
        from public.member_permissions p
       where p.tenant_id = m.tenant_id and p.user_id = m.user_id
    ), '[]'::jsonb),
    'business_name', b.business_name,
    'default_locale', b.default_locale
  )
  from public.tenant_members m
  join public.tenants t on t.id = m.tenant_id
  join public.app_users u on u.id = m.user_id
  join public.business_profiles b on b.tenant_id = m.tenant_id
  where m.user_id = auth.uid()
    and m.is_active
    and t.status = 'active'
$$;

revoke all on function public.current_session() from public, anon;
grant execute on function public.current_session() to authenticated;
