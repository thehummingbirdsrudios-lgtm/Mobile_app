-- RLS performance (Supabase advisor 0003 auth_rls_initplan).
--
-- These policies called auth.uid() directly, which Postgres may evaluate
-- once per row. Wrapping it in a scalar subquery makes it an InitPlan that
-- runs once per statement, like the tenant checks beside it. The rules are
-- unchanged: each policy keeps exactly the same meaning.

alter policy member_permissions_select on public.member_permissions
  using (
    tenant_id = (select app.current_tenant_id())
    and ((select app.is_owner()) or user_id = (select auth.uid()))
  );

alter policy remarks_update on public.remarks
  using (tenant_id = (select app.current_tenant_id()) and (created_by = (select auth.uid()) or (select app.is_owner())))
  with check (tenant_id = (select app.current_tenant_id()));

alter policy share_assets_rw on public.share_assets
  using (tenant_id = (select app.current_tenant_id()) and created_by = (select auth.uid()))
  with check (tenant_id = (select app.current_tenant_id()));

alter policy notifications_own on public.notifications
  using (tenant_id = (select app.current_tenant_id()) and recipient_id = (select auth.uid()));

alter policy notifications_mark_read on public.notifications
  using (tenant_id = (select app.current_tenant_id()) and recipient_id = (select auth.uid()))
  with check (tenant_id = (select app.current_tenant_id()) and recipient_id = (select auth.uid()));

alter policy device_tokens_own on public.device_tokens
  using (tenant_id = (select app.current_tenant_id()) and user_id = (select auth.uid()));
