import 'dart:convert';

import '../../../../core/money/money.dart';
import '../../../settings/settings.dart';
import '../../domain/orders.dart';

/// Keeps the cart on the device (never on the server until placed), one per
/// tenant/user, so a half-built order survives an app restart and is never
/// visible to another account on the same phone.
class PreferencesCartStore implements CartDraftStore {
  const PreferencesCartStore(this._prefs);

  final PreferenceStore _prefs;

  static const _version = 1;

  String _key(String scope) => 'cart.v$_version.$scope';

  @override
  CartDraft? read(String scope) {
    final raw = _prefs.getString(_key(scope));
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return null;
      return CartDraft(
        requestId: j['request_id'] as String,
        customerId: j['customer_id'] as String?,
        customerName: j['customer_name'] as String?,
        note: (j['note'] as String?) ?? '',
        reorderOf: j['reorder_of'] as String?,
        lines: [
          for (final l in (j['lines'] as List? ?? const []).cast<Map<String, dynamic>>())
            CartLine(
              productId: l['product_id'] as String,
              designNo: l['design_no'] as String,
              name: l['name'] as String,
              rate: Money.paise(l['rate_paise'] as int),
              qty: l['qty'] as int,
              isOrderable: (l['orderable'] as bool?) ?? true,
              defaultRate: l['default_rate_paise'] == null ? null : Money.paise(l['default_rate_paise'] as int),
              weightMg: l['weight_mg'] as int?,
              thumbPath: l['thumb_path'] as String?,
            ),
        ],
      );
    } on Object {
      // A corrupt or older draft is dropped rather than crashing the app.
      return null;
    }
  }

  @override
  Future<void> write(String scope, CartDraft? draft) {
    if (draft == null || (draft.isEmpty && draft.customerId == null && draft.note.isEmpty)) {
      return _prefs.setString(_key(scope), '');
    }
    return _prefs.setString(
      _key(scope),
      jsonEncode({
        'request_id': draft.requestId,
        'customer_id': draft.customerId,
        'customer_name': draft.customerName,
        'note': draft.note,
        'reorder_of': draft.reorderOf,
        'lines': [
          for (final l in draft.lines)
            {
              'product_id': l.productId,
              'design_no': l.designNo,
              'name': l.name,
              'rate_paise': l.rate.paise,
              'qty': l.qty,
              'orderable': l.isOrderable,
              'default_rate_paise': l.defaultRate?.paise,
              'weight_mg': l.weightMg,
              'thumb_path': l.thumbPath,
            },
        ],
      }),
    );
  }
}
