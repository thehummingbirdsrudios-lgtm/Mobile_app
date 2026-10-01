-- Bill line images.
--
-- The canonical image of a design is its product_media row: object-storage
-- keys for every derivative (original / catalogue 800px / share 1280px /
-- thumb 256px) plus width, height, mime type and sha256. Bills never store
-- image bytes or long-lived URLs: each line carries the storage key of the
-- design's photo AS IT WAS ORDERED (order_items.thumb_path snapshot), and
-- the client resolves it to a short-lived signed HTTPS URL, downloads it,
-- optimises it for the bill cell and embeds it in the PDF.
--
-- Private bucket + signed URLs (not public/CDN URLs) keep one business's
-- photos unreadable to anyone outside it.

-- Exact lookup of the ordered media by its thumbnail key (archived media
-- included: a bill shows what was ordered, even if the photo was replaced).
create index if not exists product_media_by_thumb
  on public.product_media (tenant_id, thumb_path)
  where thumb_path is not null;

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
                              'thumb_path', i.thumb_path,
                              -- Best stored source for a sharp bill thumbnail:
                              -- the 800px catalogue derivative of the ordered
                              -- photo (never the multi-MB original).
                              'image', case when m.id is null then null else jsonb_build_object(
                                         'source_path', coalesce(m.catalogue_path, m.thumb_path),
                                         'thumb_path', m.thumb_path,
                                         'width', m.width,
                                         'height', m.height,
                                         'sha256', m.sha256) end)
                            order by i.line_no)
                       from public.order_items i
                       left join lateral (
                         select pm.id, pm.catalogue_path, pm.thumb_path, pm.width, pm.height, pm.sha256
                           from public.product_media pm
                          where pm.tenant_id = i.tenant_id
                            and pm.thumb_path = i.thumb_path
                          limit 1) m on true
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
