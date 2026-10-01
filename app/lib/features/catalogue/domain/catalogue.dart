import 'package:meta/meta.dart';

import '../../../core/money/money.dart';
import '../../../core/state/paged.dart';

/// A design as shown in the catalogue grid.
@immutable
class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.designNo,
    required this.name,
    required this.rate,
    required this.isAvailable,
    required this.publishedAt,
    this.weightMg,
    this.thumbPath,
  });

  final String id;
  final String designNo;
  final String name;
  final Money rate;
  final bool isAvailable;
  final DateTime publishedAt;
  final int? weightMg;
  final String? thumbPath;
}

@immutable
class ProductPhoto {
  const ProductPhoto({required this.id, this.cataloguePath, this.thumbPath, this.sharePath});

  final String id;
  final String? cataloguePath;
  final String? thumbPath;
  final String? sharePath;
}

/// Owner-only commercial data. Null for staff (the server never sends it).
@immutable
class ProductPrivate {
  const ProductPrivate({this.cost, this.supplierName, this.internalNote});

  final Money? cost;
  final String? supplierName;
  final String? internalNote;
}

@immutable
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.designNo,
    required this.name,
    required this.rate,
    required this.isAvailable,
    required this.isArchived,
    required this.publishedAt,
    required this.photos,
    this.description,
    this.categoryId,
    this.categoryName,
    this.weightMg,
    this.private,
  });

  final String id;
  final String designNo;
  final String name;
  final Money rate;
  final bool isAvailable;
  final bool isArchived;
  final DateTime publishedAt;
  final List<ProductPhoto> photos;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final int? weightMg;
  final ProductPrivate? private;

  bool get isOrderable => isAvailable && !isArchived;
}

@immutable
class Category {
  const Category({required this.id, required this.name});

  final String id;
  final String name;
}

typedef CatalogueCursor = ({DateTime publishedAt, String id});

/// What the catalogue is showing.
@immutable
class CatalogueFilter {
  const CatalogueFilter({this.categoryId, this.newSince});

  /// Navo Maal: designs published in the last [days] days — the same window
  /// as the dashboard's "new maal" count. Truncated to the minute so one
  /// screen keeps one stable filter.
  factory CatalogueFilter.navoMaal(DateTime now, {int days = 7}) {
    final u = now.toUtc().subtract(Duration(days: days));
    return CatalogueFilter(newSince: DateTime.utc(u.year, u.month, u.day, u.hour, u.minute));
  }

  final String? categoryId;
  final DateTime? newSince;

  @override
  bool operator ==(Object other) =>
      other is CatalogueFilter && other.categoryId == categoryId && other.newSince == newSince;

  @override
  int get hashCode => Object.hash(categoryId, newSince);
}

/// Validation issues for a design form (pure; the server validates again).
enum ProductIssue {
  designNoRequired,
  designNoInvalid,
  nameRequired,
  nameTooLong,
  rateInvalid,
  weightInvalid,
  costInvalid,
}

/// The editable fields of a design.
@immutable
class ProductDraft {
  const ProductDraft({
    required this.designNo,
    required this.name,
    required this.rate,
    this.description,
    this.categoryId,
    this.weightMg,
    this.isAvailable = true,
    this.cost,
    this.supplierName,
    this.internalNote,
  });

  static final designNoPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9/._-]{0,23}$');

  final String designNo;
  final String name;
  final Money? rate;
  final String? description;
  final String? categoryId;
  final int? weightMg;
  final bool isAvailable;
  final Money? cost;
  final String? supplierName;
  final String? internalNote;

  bool get hasPrivateData => cost != null || (supplierName ?? '').isNotEmpty || (internalNote ?? '').isNotEmpty;

  /// Mirrors the database CHECK constraints so users see problems inline.
  Set<ProductIssue> validate() => {
    if (designNo.trim().isEmpty) ProductIssue.designNoRequired,
    if (designNo.trim().isNotEmpty && !designNoPattern.hasMatch(designNo.trim())) ProductIssue.designNoInvalid,
    if (name.trim().isEmpty) ProductIssue.nameRequired,
    if (name.trim().length > 120) ProductIssue.nameTooLong,
    if (rate == null || rate!.paise <= 0 || rate!.paise > 1000000000) ProductIssue.rateInvalid,
    if (weightMg != null && (weightMg! <= 0 || weightMg! > 100000000)) ProductIssue.weightInvalid,
    if (cost != null && (cost!.paise < 0 || cost!.paise > 1000000000)) ProductIssue.costInvalid,
  };
}

/// Catalogue port. Implementations throw `AppFailure`.
abstract interface class CatalogueRepository {
  Future<PageResult<ProductSummary, CatalogueCursor>> page(CatalogueFilter filter, {CatalogueCursor? after, int limit});

  Future<ProductDetail?> detail(String productId);

  Future<List<Category>> categories();

  Future<Category> createCategory(String name);

  /// Creates a design and returns its id.
  Future<String> create(ProductDraft draft, {required bool includePrivate});

  Future<void> update(String productId, ProductDraft draft, {required bool includeRate, required bool includePrivate});

  Future<void> setArchived(String productId, {required bool archived});

  Future<void> addPhoto(String productId, PhotoUpload upload);

  Future<void> removePhoto(String photoId);
}

/// A processed photo ready to upload (bytes come from the image pipeline).
@immutable
class PhotoUpload {
  const PhotoUpload({
    required this.tenantId,
    required this.original,
    required this.originalMime,
    required this.catalogue,
    required this.share,
    required this.thumb,
    required this.width,
    required this.height,
    required this.sha256,
    required this.sortOrder,
  });

  final String tenantId;
  final List<int> original;
  final String originalMime;
  final List<int> catalogue;
  final List<int> share;
  final List<int> thumb;
  final int width;
  final int height;
  final String sha256;
  final int sortOrder;
}
