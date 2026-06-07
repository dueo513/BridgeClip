import 'package:clipboard_sync/services/app_lock_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('app lock stores hashed PIN and verifies it', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await AppLockService.isEnabled(), isFalse);

    await AppLockService.enable('1234');

    expect(await AppLockService.isEnabled(), isTrue);
    expect(await AppLockService.verify('1234'), isTrue);
    expect(await AppLockService.verify('0000'), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appLockHash'), isNot('1234'));

    await AppLockService.disable();

    expect(await AppLockService.isEnabled(), isFalse);
    expect(await AppLockService.verify('1234'), isFalse);
  });
}
