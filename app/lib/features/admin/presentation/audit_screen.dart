import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../application/admin_providers.dart';
import '../domain/admin.dart';
import 'admin_labels.dart';

/// Owner-only activity log: who changed what, and when. Newest first.
class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return OwnerOnly(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.adminAudit)),
        body: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(auditLogProvider);
            final notifier = ref.read(auditLogProvider.notifier);
            return RefreshIndicator(
              onRefresh: notifier.refresh,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      PagedSliverBody<AuditEntry, int>(
                        state: state,
                        padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.huge),
                        onLoadMore: notifier.loadMore,
                        onRetry: notifier.retry,
                        itemBuilder: (context, e) => _AuditTile(entry: e),
                        skeleton: const Center(
                          child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator()),
                        ),
                        empty: EmptyState(icon: Icons.history_rounded, title: l10n.auditEmpty),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final who = entry.actorName ?? l10n.auditSystem;
    return ListTile(
      title: Text(auditTitle(l10n, entry)),
      subtitle: Text(
        [?entry.subject, '$who · ${AppFormat.dateTime(entry.createdAt, locale)}'].join('\n'),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: entry.subject != null,
    );
  }
}
