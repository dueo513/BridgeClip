import 'package:clipboard_sync/services/clipboard_upload_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deduplicates queued and recently uploaded clipboard text', () async {
    final uploads = <String>[];
    final coordinator = ClipboardUploadCoordinator(
      (text) async => uploads.add(text),
      duplicateWindow: const Duration(seconds: 10),
    );

    expect(coordinator.enqueue('hello'), isTrue);
    expect(coordinator.enqueue('hello'), isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(uploads, ['hello']);
    expect(coordinator.enqueue('hello'), isFalse);

    coordinator.dispose();
  });

  test(
    'keeps queued text and retries after temporary upload failure',
    () async {
      final uploads = <String>[];
      var attempts = 0;
      final coordinator = ClipboardUploadCoordinator((text) async {
        attempts++;
        if (attempts == 1) {
          throw StateError('temporary failure');
        }
        uploads.add(text);
      });

      expect(coordinator.enqueue('retry-me'), isTrue);

      await Future<void>.delayed(const Duration(seconds: 1));

      expect(attempts, 2);
      expect(uploads, ['retry-me']);

      coordinator.dispose();
    },
  );
}
