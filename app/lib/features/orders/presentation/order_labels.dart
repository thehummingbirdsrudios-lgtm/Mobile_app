import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/orders.dart';

String orderStatusLabel(AppLocalizations l10n, OrderStatus s) => switch (s) {
  OrderStatus.confirmed => l10n.statusConfirmed,
  OrderStatus.processing => l10n.statusProcessing,
  OrderStatus.ready => l10n.statusReady,
  OrderStatus.completed => l10n.statusCompleted,
  OrderStatus.cancelled => l10n.statusCancelled,
};

StatusTone orderStatusTone(OrderStatus s) => switch (s) {
  OrderStatus.confirmed => StatusTone.accent,
  OrderStatus.processing || OrderStatus.ready => StatusTone.warning,
  OrderStatus.completed => StatusTone.success,
  OrderStatus.cancelled => StatusTone.neutral,
};

String paymentModeLabel(AppLocalizations l10n, PaymentMode m) => switch (m) {
  PaymentMode.cash => l10n.paymentModeCash,
  PaymentMode.upi => l10n.paymentModeUpi,
  PaymentMode.bank => l10n.paymentModeBank,
  PaymentMode.cheque => l10n.paymentModeCheque,
};
