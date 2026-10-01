import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../customers/customers.dart';

/// Bottom sheet to choose who the order is for. Returns (id, name) or null.
Future<({String id, String name})?> showCustomerPicker(BuildContext context) =>
    showModalBottomSheet<({String id, String name})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const FractionallySizedBox(heightFactor: 0.9, child: _CustomerPicker()),
    );

class _CustomerPicker extends ConsumerStatefulWidget {
  const _CustomerPicker();

  @override
  ConsumerState<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends ConsumerState<_CustomerPicker> {
  var _query = const CustomerQuery();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final list = ref.watch(customerListProvider(_query));
    final notifier = ref.read(customerListProvider(_query).notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Text(l10n.customerPickerTitle, style: text.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: AppSearchField(
            hint: l10n.customerSearchHint,
            autofocus: true,
            onQuery: (q) => setState(() => _query = CustomerQuery(search: q)),
          ),
        ),
        Expanded(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              PagedSliverBody<CustomerSummary, Object?>(
                state: list,
                onLoadMore: notifier.loadMore,
                onRetry: notifier.retry,
                itemBuilder: (context, c) => CustomerTile(
                  name: c.name,
                  subtitle: c.place ?? c.phone,
                  onTap: () => Navigator.of(context).pop((id: c.id, name: c.name)),
                ),
                skeleton: const Center(child: CircularProgressIndicator()),
                empty: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: _query.search.isEmpty ? l10n.customersEmpty : l10n.customersNoMatch(_query.search),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
