import '../../domain/export.dart';
import '../remote/export_api.dart';

class ExportRepositoryImpl implements ExportRepository {
  const ExportRepositoryImpl(this._remote);

  final ExportApi _remote;

  @override
  Future<ExportPage> page(ExportKind kind, {ExportRange? range, Object? after}) =>
      _remote.page(kind, range: range, after: after);
}
