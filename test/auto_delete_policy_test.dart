import 'package:clipboard_sync/services/auto_delete_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not delete items that existed before timer activation', () {
    final activatedAt = DateTime(2026, 6, 7, 12);
    final oldItem = activatedAt.subtract(const Duration(hours: 2));
    final now = activatedAt.add(const Duration(hours: 3));

    expect(
      AutoDeletePolicy.shouldDelete(
        itemTimestamp: oldItem,
        isPinned: false,
        autoDeleteMinutes: 10,
        activatedAt: activatedAt,
        now: now,
      ),
      isFalse,
    );
  });

  test('deletes unpinned items created after activation when expired', () {
    final activatedAt = DateTime(2026, 6, 7, 12);
    final newItem = activatedAt.add(const Duration(minutes: 1));
    final now = newItem.add(const Duration(minutes: 10));

    expect(
      AutoDeletePolicy.shouldDelete(
        itemTimestamp: newItem,
        isPinned: false,
        autoDeleteMinutes: 10,
        activatedAt: activatedAt,
        now: now,
      ),
      isTrue,
    );
  });

  test('keeps pinned items even when expired', () {
    final activatedAt = DateTime(2026, 6, 7, 12);
    final newItem = activatedAt.add(const Duration(minutes: 1));
    final now = newItem.add(const Duration(days: 1));

    expect(
      AutoDeletePolicy.shouldDelete(
        itemTimestamp: newItem,
        isPinned: true,
        autoDeleteMinutes: 10,
        activatedAt: activatedAt,
        now: now,
      ),
      isFalse,
    );
  });
}
