import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/admin_providers.dart';
import '../domain/admin.dart';
import 'admin_labels.dart';
import 'password_field.dart';

/// Everyone in the business: the owner first, then staff by name.
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) => const OwnerOnly(child: _StaffList());
}

class _StaffList extends ConsumerWidget {
  const _StaffList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final nav = ref.read(appNavigatorProvider);
    final members = ref.watch(staffMembersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminStaff)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: nav.openAddStaff,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(l10n.staffAdd),
      ),
      body: switch (members) {
        AsyncValue(:final value?) => RefreshIndicator(
          onRefresh: () => ref.refresh(staffMembersProvider.future),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
              child: ListView(
                padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.huge * 2),
                children: [
                  for (final m in value) _MemberTile(member: m, onTap: () => nav.openStaffMember(m.userId)),
                  if (!value.any((m) => !m.isOwner))
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: EmptyState(icon: Icons.groups_outlined, title: l10n.staffEmpty, body: l10n.staffEmptyBody),
                    ),
                ],
              ),
            ),
          ),
        ),
        AsyncError(:final error) => ErrorState(
          failure: AppFailure.from(error),
          onRetry: () => ref.refresh(staffMembersProvider.future),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onTap});

  final StaffMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, tone) = member.isOwner
        ? (l10n.roleOwner, StatusTone.accent)
        : member.isActive
        ? (l10n.staffActive, StatusTone.success)
        : (l10n.staffInactive, StatusTone.neutral);
    return ListTile(
      onTap: member.isOwner ? null : onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceMuted,
        foregroundColor: AppColors.ink,
        child: Text(member.displayName.characters.first.toUpperCase()),
      ),
      title: Text(member.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        member.isOwner
            ? '@${member.username}'
            : '@${member.username} · ${l10n.staffPermissionCount(member.permissions.length)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: StatusChip(label: label, tone: tone),
    );
  }
}

/// One staff member: access on/off, permissions, new password.
class StaffDetailScreen extends StatelessWidget {
  const StaffDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) => OwnerOnly(child: _StaffDetailLoader(userId: userId));
}

class _StaffDetailLoader extends ConsumerWidget {
  const _StaffDetailLoader({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final member = ref.watch(staffMemberProvider(userId));
    return switch (member) {
      AsyncValue(value: StaffMember(isOwner: true)) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.verified_user_outlined, title: l10n.staffOwnerHasAll),
      ),
      AsyncValue(:final value?) => _StaffDetail(member: value),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.search_off_rounded, title: l10n.commonNotFound),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(failure: AppFailure.from(error), onRetry: () => ref.refresh(staffMembersProvider.future)),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _StaffDetail extends ConsumerStatefulWidget {
  const _StaffDetail({required this.member});

  final StaffMember member;

  @override
  ConsumerState<_StaffDetail> createState() => _StaffDetailState();
}

class _StaffDetailState extends ConsumerState<_StaffDetail> {
  late Set<Permission> _selected = {...widget.member.permissions};
  bool _savingAccess = false;

  bool get _changed =>
      _selected.length != widget.member.permissions.length || !_selected.containsAll(widget.member.permissions);

  @override
  void didUpdateWidget(_StaffDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Server state changed (saved here or elsewhere) and nothing is pending.
    if (!_samePermissions(oldWidget.member.permissions, _selected)) return;
    _selected = {...widget.member.permissions};
  }

  static bool _samePermissions(Set<Permission> a, Set<Permission> b) => a.length == b.length && a.containsAll(b);

  Future<void> _savePermissions() async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(adminActionsProvider).setPermissions(widget.member.userId, _selected);
      if (mounted) AppFeedback.show(context, l10n.commonSaved);
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  Future<void> _setActive(bool active) async {
    final l10n = AppLocalizations.of(context);
    final m = widget.member;
    if (!active) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.staffDeactivateTitle(m.displayName)),
          content: Text(l10n.staffDeactivateBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonCancel)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.staffDeactivate),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _savingAccess = true);
    try {
      await ref.read(adminActionsProvider).setActive(m.userId, active: active);
      if (mounted) AppFeedback.show(context, active ? l10n.staffAccessRestored : l10n.staffAccessStopped);
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    } finally {
      if (mounted) setState(() => _savingAccess = false);
    }
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context);
    final password = await showNewPasswordDialog(context, name: widget.member.displayName);
    if (password == null || !mounted) return;
    try {
      await ref.read(adminActionsProvider).resetPassword(widget.member.userId, password);
      if (mounted) AppFeedback.show(context, l10n.staffPasswordChanged);
    } on AppFailure catch (f) {
      if (mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final m = widget.member;

    return UnsavedChangesGuard(
      hasUnsavedChanges: _changed,
      child: Scaffold(
        appBar: AppBar(title: Text(m.displayName)),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.maxListWidth),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  child: Text('@${m.username}', style: text.bodyMedium!.copyWith(color: AppColors.muted)),
                ),
                SwitchListTile(
                  title: Text(l10n.staffAccess),
                  subtitle: Text(l10n.staffAccessHint),
                  value: m.isActive,
                  onChanged: _savingAccess ? null : (v) => unawaited(_setActive(v)),
                ),
                const Divider(indent: AppSpacing.gutter, endIndent: AppSpacing.gutter),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
                  child: Text(l10n.staffPermissions, style: text.titleMedium),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xxs, AppSpacing.gutter, 0),
                  child: Text(l10n.staffPermissionsHint, style: text.bodySmall),
                ),
                for (final p in Permission.values)
                  CheckboxListTile(
                    value: _selected.contains(p),
                    title: Text(permissionLabel(l10n, p)),
                    onChanged: (v) => setState(() => v == true ? _selected.add(p) : _selected.remove(p)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: AppButton(
                    label: l10n.staffSavePermissions,
                    icon: Icons.check_rounded,
                    onPressed: _changed ? _savePermissions : null,
                  ),
                ),
                const Divider(indent: AppSpacing.gutter, endIndent: AppSpacing.gutter),
                ListTile(
                  leading: const Icon(Icons.password_rounded),
                  title: Text(l10n.staffResetPassword),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => unawaited(_resetPassword()),
                ),
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
