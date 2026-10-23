import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/media_item.dart';
import '../../services/media_service.dart';
import '../../theme/cixio_theme.dart';

/// Voice + camera capture screen.
///
/// Files are saved locally first and uploaded to S3 in the background; the
/// list below reflects each item's upload status in real time.
class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final MediaService _media = MediaService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Idempotent — main.dart also primes the service at startup.
    unawaited(_media.init());
  }

  Future<void> _capture(
      Future<MediaItem?> Function() action, String label) async {
    if (_busy) return;
    setState(() => _busy = true);
    final item = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (item != null) {
      _toast('$label saved locally — uploading…');
    } else if (_media.lastError != null) {
      _toast(_media.lastError!);
    }
  }

  Future<void> _recordVoice() async {
    if (_busy) return;
    final item = await showModalBottomSheet<MediaItem>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: CixioColors.dark,
      builder: (_) => _VoiceRecordSheet(media: _media),
    );
    if (!mounted) return;
    if (item != null) {
      _toast('Voice note saved locally — uploading…');
    } else if (_media.lastError != null) {
      _toast(_media.lastError!);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _media,
      builder: (context, _) {
        final items = _media.items;
        return Column(
          children: [
            _statusCard(),
            _captureBar(),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      onRefresh: _media.syncNow,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _MediaTile(item: items[index], media: _media),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _statusCard() {
    final configured = _media.uploadConfigured;
    final pending = _media.pendingCount;
    return Container(
      width: double.infinity,
      color: configured ? CixioColors.light : const Color(0xFFFFF4E5),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          if (_media.isSyncing)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              configured ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              size: 20,
              color: configured ? CixioColors.blue : const Color(0xFFB26A00),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              !configured
                  ? 'S3 upload not configured — files are kept locally and retried.'
                  : _media.isSyncing
                      ? 'Uploading…'
                      : pending == 0
                          ? 'All files uploaded.'
                          : '$pending file${pending == 1 ? '' : 's'} waiting to upload (retries every 2 min).',
              style: const TextStyle(fontSize: 13, color: CixioColors.dark),
            ),
          ),
          if (configured && !_media.isSyncing && pending > 0)
            TextButton(
              onPressed: _media.syncNow,
              child: const Text('Sync now'),
            ),
        ],
      ),
    );
  }

  Widget _captureBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _CaptureButton(
              icon: Icons.mic,
              label: 'Voice',
              color: Colors.red,
              enabled: !_busy,
              onTap: _recordVoice,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CaptureButton(
              icon: Icons.photo_camera,
              label: 'Photo',
              color: CixioColors.blue,
              enabled: !_busy,
              onTap: () => _capture(_media.capturePhoto, 'Photo'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CaptureButton(
              icon: Icons.videocam,
              label: 'Video',
              color: CixioColors.navy,
              enabled: !_busy,
              onTap: () => _capture(_media.captureVideo, 'Video'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled ? onTap : null,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.item, required this.media});

  final MediaItem item;
  final MediaService media;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading:
            Icon(_iconFor(item.type), color: _colorFor(item.type), size: 32),
        title:
            Text(item.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${item.type.name} • ${_formatSize(item.sizeBytes)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusChip(item),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete file?'),
        content: const Text(
          'This removes the local copy and, if it was uploaded, deletes the '
          'file from the cloud too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await media.delete(item.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('"${item.fileName}" deleted.')),
        );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not delete from the cloud: $e')),
        );
    }
  }

  Widget _statusChip(MediaItem item) {
    late final Color color;
    late final String label;
    Widget? leading;
    switch (item.status) {
      case UploadStatus.uploaded:
        color = Colors.green;
        label = 'Uploaded';
      case UploadStatus.uploading:
        color = CixioColors.blue;
        label = 'Uploading';
        leading = const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        );
      case UploadStatus.pending:
        color = Colors.orange;
        label = 'Pending';
      case UploadStatus.failed:
        color = Colors.red;
        label = item.attempts > 1 ? 'Retry ${item.attempts}' : 'Failed';
    }
    return Tooltip(
      message: item.lastError ?? label,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 6)],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(MediaType type) => switch (type) {
        MediaType.voice => Icons.mic,
        MediaType.photo => Icons.image,
        MediaType.video => Icons.movie,
      };

  Color _colorFor(MediaType type) => switch (type) {
        MediaType.voice => Colors.red,
        MediaType.photo => CixioColors.blue,
        MediaType.video => CixioColors.navy,
      };

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 56, color: CixioColors.muted),
            SizedBox(height: 12),
            Text(
              'No media yet.\nRecord a voice note or capture a photo / video.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CixioColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet that records audio until the user stops or cancels.
class _VoiceRecordSheet extends StatefulWidget {
  const _VoiceRecordSheet({required this.media});

  final MediaService media;

  @override
  State<_VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

class _VoiceRecordSheetState extends State<_VoiceRecordSheet> {
  Timer? _ticker;
  int _seconds = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final ok = await widget.media.startRecording();
    if (!mounted) return;
    if (!ok) {
      Navigator.pop(context);
      return;
    }
    setState(() => _started = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    final item = await widget.media.stopRecording();
    if (mounted) Navigator.pop(context, item);
  }

  Future<void> _cancel() async {
    _ticker?.cancel();
    await widget.media.cancelRecording();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _cancel,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Spacer(),
                const Text(
                  'Voice note',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.mic,
              size: 64,
              color: _started ? Colors.red : CixioColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              _formatDuration(_seconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    onPressed: _cancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _started ? _stop : null,
                    child: const Text('Stop & save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
