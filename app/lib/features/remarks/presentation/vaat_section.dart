import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth.dart';
import '../application/remark_providers.dart';
import '../domain/remarks.dart';

String _clock(Duration d) =>
    '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Vaat: internal notes on a customer, order or design — typed, spoken or
/// photographed. Shared by everyone in the business; never sent outside.
class VaatSection extends ConsumerStatefulWidget {
  const VaatSection({super.key, required this.target});

  final RemarkTarget target;

  @override
  ConsumerState<VaatSection> createState() => _VaatSectionState();
}

class _VaatSectionState extends ConsumerState<VaatSection> {
  final _text = TextEditingController();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _recording = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (_recording) unawaited(ref.read(voiceRecorderProvider).cancel());
    _text.dispose();
    super.dispose();
  }

  void _error(Object error) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final message = error is ImageRejectedException ? l10n.photoRejected : AppFailure.from(error).message(l10n);
    AppFeedback.show(context, message, tone: FeedbackTone.error);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendText() => _run(() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    await ref.read(remarkWriterProvider).addText(widget.target, text);
    _text.clear();
  });

  Future<void> _startRecording() async {
    final l10n = AppLocalizations.of(context);
    final recorder = ref.read(voiceRecorderProvider);
    try {
      if (!await recorder.ensurePermission()) {
        if (mounted) AppFeedback.show(context, l10n.vaatMicDenied, tone: FeedbackTone.warning);
        return;
      }
      await recorder.start();
    } on Object catch (e) {
      _error(e);
      return;
    }
    if (!mounted) return;
    setState(() {
      _recording = true;
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= RemarkLimits.maxVoice) unawaited(_stopRecording(send: true));
    });
  }

  Future<void> _stopRecording({required bool send}) async {
    final l10n = AppLocalizations.of(context);
    _ticker?.cancel();
    _ticker = null;
    setState(() => _recording = false);
    final recorder = ref.read(voiceRecorderProvider);
    if (!send) return recorder.cancel();
    await _run(() async {
      final audio = await recorder.stop();
      if (audio == null || audio.duration < RemarkLimits.minVoice) {
        if (mounted) AppFeedback.show(context, l10n.vaatTooShort, tone: FeedbackTone.warning);
        return;
      }
      await ref.read(remarkWriterProvider).addVoice(widget.target, audio);
    });
  }

  Future<void> _addPhoto() => _run(() async {
    final picked = await ref.read(photoPickerProvider).pick(PhotoOrigin.camera);
    if (picked == null) return;
    await ref.read(remarkWriterProvider).addPhoto(widget.target, picked);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final remarks = ref.watch(remarksProvider(widget.target));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.forum_outlined, color: AppColors.goldText, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(l10n.commonVaat, style: text.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_recording)
          _RecordingBar(
            elapsed: _elapsed,
            onCancel: () => _stopRecording(send: false),
            onSend: () => _stopRecording(send: true),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: RemarkLimits.maxText,
                  buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
                  decoration: InputDecoration(hintText: l10n.vaatHint),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (_text.text.trim().isNotEmpty)
                IconButton.filled(
                  tooltip: l10n.vaatSend,
                  onPressed: _busy ? null : _sendText,
                  icon: const Icon(Icons.send_rounded),
                )
              else ...[
                IconButton.filledTonal(
                  tooltip: l10n.vaatAddPhoto,
                  onPressed: _busy ? null : _addPhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                ),
                IconButton.filled(
                  tooltip: l10n.vaatRecord,
                  onPressed: _busy ? null : _startRecording,
                  icon: const Icon(Icons.mic_rounded),
                ),
              ],
            ],
          ),
        if (_busy) const LinearProgressIndicator(minHeight: 2, color: AppColors.ink),
        const SizedBox(height: AppSpacing.sm),
        switch (remarks) {
          AsyncData(:final value) when value.isEmpty => Text(
            l10n.vaatEmpty,
            style: text.bodyMedium!.copyWith(color: AppColors.muted),
          ),
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final r in value) _RemarkTile(remark: r, target: widget.target)],
          ),
          AsyncError(:final error) => ErrorState(
            failure: AppFailure.from(error),
            onRetry: () => ref.refresh(remarksProvider(widget.target).future),
          ),
          _ => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}

class _RecordingBar extends StatelessWidget {
  const _RecordingBar({required this.elapsed, required this.onCancel, required this.onSend});

  final Duration elapsed;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: const BoxDecoration(color: AppColors.errorTint, borderRadius: AppRadius.control),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.vaatRecording(_clock(elapsed)),
                style: text.titleMedium!.copyWith(fontFeatures: AppType.figures),
              ),
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
          IconButton.filled(tooltip: l10n.vaatSend, onPressed: onSend, icon: const Icon(Icons.send_rounded)),
        ],
      ),
    );
  }
}

class _RemarkTile extends ConsumerWidget {
  const _RemarkTile({required this.remark, required this.target});

  final Remark remark;
  final RemarkTarget target;

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(remarkWriterProvider).archive(target, remark.id);
    } on AppFailure catch (f) {
      if (context.mounted) AppFeedback.show(context, f.message(l10n), tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final session = ref.watch(currentSessionProvider);
    final mine = remark.authorId != null && remark.authorId == session?.userId;
    final canRemove = mine || (session?.isOwner ?? false);
    final r = remark;

    final Widget body = switch (r.kind) {
      RemarkKind.text => SelectableText(r.text ?? '', style: text.bodyLarge),
      RemarkKind.voice => _VoiceNote(remark: r),
      RemarkKind.photo => GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(AppSpacing.md),
            child: InteractiveViewer(
              child: RemoteImage(path: r.mediaPath, bucket: Buckets.remarks, fit: BoxFit.contain),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.control,
          child: SizedBox(
            height: 160,
            child: RemoteImage(path: r.mediaPath, bucket: Buckets.remarks, decodeWidth: 480),
          ),
        ),
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: mine ? AppColors.goldTint.withValues(alpha: 0.45) : AppColors.surfaceMuted,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  [if (mine) l10n.vaatYou else ?r.authorName, AppFormat.dateTime(r.createdAt, locale)].join(' · '),
                  style: text.bodySmall!.copyWith(color: AppColors.muted),
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: l10n.vaatRemove,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: () => _archive(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          body,
        ],
      ),
    );
  }
}

class _VoiceNote extends ConsumerStatefulWidget {
  const _VoiceNote({required this.remark});

  final Remark remark;

  @override
  ConsumerState<_VoiceNote> createState() => _VoiceNoteState();
}

class _VoiceNoteState extends ConsumerState<_VoiceNote> {
  StreamSubscription<String?>? _sub;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(voicePlayerProvider).nowPlaying.listen((id) {
      if (mounted) setState(() => _playing = id == widget.remark.id);
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  Future<void> _toggle() async {
    final l10n = AppLocalizations.of(context);
    final player = ref.read(voicePlayerProvider);
    if (_playing) return player.stop();
    try {
      final url = await ref.read(signedUrlCacheProvider).get((bucket: Buckets.remarks, path: widget.remark.mediaPath!));
      await player.play(widget.remark.id, url);
    } on Object catch (e) {
      if (mounted) AppFeedback.show(context, AppFailure.from(e).message(l10n), tone: FeedbackTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        IconButton.filled(
          tooltip: _playing ? l10n.vaatStop : l10n.vaatPlay,
          onPressed: _toggle,
          icon: Icon(_playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
        const Icon(Icons.graphic_eq_rounded, color: AppColors.muted),
        const SizedBox(width: AppSpacing.xs),
        Text(
          _clock(widget.remark.duration ?? Duration.zero),
          style: text.bodyLarge!.copyWith(fontFeatures: AppType.figures),
        ),
      ],
    );
  }
}
