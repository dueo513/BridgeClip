import 'package:clipboard_sync/services/crypto_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('content hash is deterministic and key scoped', () async {
    await CryptoService.instance.init('room-password');

    final first = await CryptoService.instance.contentHash('same text');
    final second = await CryptoService.instance.contentHash('same text');
    final differentText = await CryptoService.instance.contentHash(
      'other text',
    );

    expect(second, first);
    expect(differentText, isNot(first));

    await CryptoService.instance.init('other-password');
    final differentPassword = await CryptoService.instance.contentHash(
      'same text',
    );

    expect(differentPassword, isNot(first));
  });
}
