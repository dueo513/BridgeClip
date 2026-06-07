import 'dart:async';
import 'dart:collection';

typedef ClipboardUpload = Future<void> Function(String text);

class ClipboardUploadCoordinator {
  ClipboardUploadCoordinator(
    this._upload, {
    this.duplicateWindow = const Duration(seconds: 2),
  });

  final ClipboardUpload _upload;
  final Duration duplicateWindow;
  final ListQueue<String> _queue = ListQueue<String>();
  final Set<String> _queuedTexts = <String>{};

  Timer? _retryTimer;
  bool _isDraining = false;
  bool _isDisposed = false;
  String? _lastAcceptedText;
  DateTime? _lastAcceptedAt;
  String? _lastUploadedText;
  DateTime? _lastUploadedAt;
  int _nextRetryDelaySeconds = 2;

  int get pendingCount => _queue.length;

  bool enqueue(String text) {
    final candidate = text.trim();
    if (candidate.isEmpty || _isDisposed) return false;
    if (_isQueued(candidate) ||
        _isRecentlyAccepted(candidate) ||
        _isRecentUploadDuplicate(candidate)) {
      return false;
    }

    _lastAcceptedText = candidate;
    _lastAcceptedAt = DateTime.now();
    _queuedTexts.add(candidate);
    _queue.add(candidate);
    _retryTimer?.cancel();
    _drain();
    return true;
  }

  void dispose() {
    _isDisposed = true;
    _retryTimer?.cancel();
    _queue.clear();
    _queuedTexts.clear();
  }

  bool _isQueued(String text) => _queuedTexts.contains(text);

  bool _isRecentlyAccepted(String text) {
    final now = DateTime.now();
    final acceptedAt = _lastAcceptedAt;
    return _lastAcceptedText == text &&
        acceptedAt != null &&
        now.difference(acceptedAt) < duplicateWindow;
  }

  bool _isRecentUploadDuplicate(String text) {
    final now = DateTime.now();
    final uploadedAt = _lastUploadedAt;
    return _lastUploadedText == text &&
        uploadedAt != null &&
        now.difference(uploadedAt) < duplicateWindow;
  }

  Future<void> _drain() async {
    if (_isDraining || _isDisposed) return;
    _isDraining = true;

    try {
      while (_queue.isNotEmpty && !_isDisposed) {
        final text = _queue.removeFirst();
        _queuedTexts.remove(text);

        if (_isRecentUploadDuplicate(text)) continue;

        final uploaded = await _uploadWithRetry(text);
        if (!uploaded) {
          _queue.addFirst(text);
          _queuedTexts.add(text);
          _scheduleRetry();
          return;
        }

        _lastUploadedText = text;
        _lastUploadedAt = DateTime.now();
        _nextRetryDelaySeconds = 2;
      }
    } finally {
      _isDraining = false;
    }
  }

  Future<bool> _uploadWithRetry(String text) async {
    var delay = const Duration(milliseconds: 250);

    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        await _upload(text);
        return true;
      } catch (_) {
        if (attempt == 3) return false;
        await Future<void>.delayed(delay);
        delay *= 2;
      }
    }

    return false;
  }

  void _scheduleRetry() {
    if (_isDisposed) return;
    final delay = Duration(seconds: _nextRetryDelaySeconds);
    _nextRetryDelaySeconds = (_nextRetryDelaySeconds * 2).clamp(2, 30);
    _retryTimer = Timer(delay, _drain);
  }
}
