import '../../../../core/money/money.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/catalogue.dart';

ProductSummary productSummaryFromJson(Map<String, dynamic> j) => ProductSummary(
  id: j.requireString('id'),
  designNo: j.requireString('design_no'),
  name: j.requireString('name'),
  rate: Money.paise(j.requireInt('rate_paise')),
  isAvailable: j['is_available'] == true,
  publishedAt: DateTime.parse(j.requireString('published_at')),
  weightMg: j['weight_mg'] == null ? null : j.requireInt('weight_mg'),
  thumbPath: j.optionalString('thumb_path'),
);

ProductDetail productDetailFromJson(Map<String, dynamic> j) {
  final private = j['private'];
  return ProductDetail(
    id: j.requireString('id'),
    designNo: j.requireString('design_no'),
    name: j.requireString('name'),
    rate: Money.paise(j.requireInt('rate_paise')),
    isAvailable: j['is_available'] == true,
    isArchived: j.requireString('status') == 'archived',
    publishedAt: DateTime.parse(j.requireString('published_at')),
    description: j.optionalString('description'),
    categoryId: j.optionalString('category_id'),
    categoryName: j.optionalString('category_name'),
    weightMg: j['weight_mg'] == null ? null : j.requireInt('weight_mg'),
    photos: [
      for (final m in (j['media'] as List? ?? const []))
        ProductPhoto(
          id: asJsonObject(m).requireString('id'),
          cataloguePath: asJsonObject(m).optionalString('catalogue_path'),
          thumbPath: asJsonObject(m).optionalString('thumb_path'),
          sharePath: asJsonObject(m).optionalString('share_path'),
        ),
    ],
    private: private == null
        ? null
        : () {
            final p = asJsonObject(private);
            return ProductPrivate(
              cost: p['cost_paise'] == null ? null : Money.paise(p.requireInt('cost_paise')),
              supplierName: p.optionalString('supplier_name'),
              internalNote: p.optionalString('internal_note'),
            );
          }(),
  );
}

/// Column map for inserts/updates (only client-writable columns).
Map<String, Object?> productColumns(ProductDraft d, {required bool includeRate}) => {
  'design_no': d.designNo.trim(),
  'name': d.name.trim(),
  'description': (d.description ?? '').trim().isEmpty ? null : d.description!.trim(),
  'category_id': d.categoryId,
  if (includeRate) 'rate_paise': d.rate!.paise,
  'weight_mg': d.weightMg,
  'is_available': d.isAvailable,
};

Map<String, Object?> privateColumns(ProductDraft d) => {
  'cost_paise': d.cost?.paise,
  'supplier_name': (d.supplierName ?? '').trim().isEmpty ? null : d.supplierName!.trim(),
  'internal_note': (d.internalNote ?? '').trim().isEmpty ? null : d.internalNote!.trim(),
};
