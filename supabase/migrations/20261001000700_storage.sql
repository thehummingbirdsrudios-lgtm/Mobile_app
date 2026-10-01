-- Private Storage buckets. Object keys MUST start with the owning tenant id:
--   {tenant_id}/{entity}/{uuid}/{variant}.{ext}
-- Policies check that first folder against the caller's tenant, so a guessed
-- or leaked key from another tenant is useless. Buckets are private: reads go
-- through short-lived signed URLs created for an authorised session.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('product-media', 'product-media', false, 26214400,
     array['image/jpeg', 'image/png', 'image/webp', 'video/mp4']),
  ('remarks', 'remarks', false, 15728640,
     array['audio/aac', 'audio/mp4', 'audio/m4a', 'audio/x-m4a', 'audio/mpeg', 'audio/ogg', 'audio/webm',
           'image/jpeg', 'image/png', 'image/webp']),
  ('bills', 'bills', false, 10485760, array['application/pdf']),
  ('share', 'share', false, 10485760, array['image/jpeg', 'image/png', 'application/pdf']),
  ('branding', 'branding', false, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create or replace function app.object_in_my_tenant(p_name text) returns boolean
language sql stable
set search_path = ''
as $$
  select (storage.foldername(p_name))[1] = (select app.current_tenant_id())::text
$$;
grant execute on function app.object_in_my_tenant(text) to authenticated;

-- Read: own tenant only. Bill PDFs carry customer Baki, so they need the
-- same permission as the bills table (bills.issue or hisaab.view).
create policy vepari_objects_select on storage.objects for select to authenticated
  using (
    app.object_in_my_tenant(name)
    and (
      bucket_id in ('product-media', 'remarks', 'share', 'branding')
      or (bucket_id = 'bills' and (app.has_permission('bills.issue') or app.has_permission('hisaab.view')))
    )
  );

-- Write rules per bucket.
create policy vepari_objects_insert on storage.objects for insert to authenticated
  with check (
    app.object_in_my_tenant(name)
    and (
      (bucket_id = 'product-media' and app.has_permission('catalogue.manage'))
      or bucket_id = 'remarks'
      or (bucket_id = 'bills' and app.has_permission('bills.issue'))
      or bucket_id = 'share'
      or (bucket_id = 'branding' and app.is_owner())
    )
  );

-- Overwrites only for regenerable derivatives; originals are write-once.
-- WITH CHECK repeats the bucket rules so an update can never MOVE an object
-- into another bucket (e.g. share → bills) and bypass its insert rules.
create policy vepari_objects_update on storage.objects for update to authenticated
  using (
    app.object_in_my_tenant(name)
    and (
      (bucket_id = 'bills' and app.has_permission('bills.issue'))
      or bucket_id = 'share'
      or (bucket_id = 'branding' and app.is_owner())
    )
  )
  with check (
    app.object_in_my_tenant(name)
    and (
      (bucket_id = 'bills' and app.has_permission('bills.issue'))
      or bucket_id = 'share'
      or (bucket_id = 'branding' and app.is_owner())
    )
  );

-- Deletes: temporary share files (cleanup) and the owner's own branding.
create policy vepari_objects_delete on storage.objects for delete to authenticated
  using (
    app.object_in_my_tenant(name)
    and (bucket_id = 'share' or (bucket_id = 'branding' and app.is_owner()))
  );
