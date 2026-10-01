import '../../l10n/app_localizations.dart';
import '../money/payment_mode.dart';

String paymentModeLabel(AppLocalizations l10n, PaymentMode m) => switch (m) {
  PaymentMode.cash => l10n.paymentModeCash,
  PaymentMode.upi => l10n.paymentModeUpi,
  PaymentMode.bank => l10n.paymentModeBank,
  PaymentMode.cheque => l10n.paymentModeCheque,
};
