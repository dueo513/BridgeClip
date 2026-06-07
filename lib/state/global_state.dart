import 'package:flutter/foundation.dart';

class GlobalState {
  static String? pendingSelectCopyText;
  static final ValueNotifier<String?> selectCopyNotifier =
      ValueNotifier<String?>(null);

  static String? pendingCopyText;
  static final ValueNotifier<String?> copyNotifier = ValueNotifier<String?>(
    null,
  );

  static String? pendingJoinRoomId;
  static final ValueNotifier<String?> joinRoomNotifier = ValueNotifier<String?>(
    null,
  );
}
