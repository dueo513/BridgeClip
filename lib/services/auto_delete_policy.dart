class AutoDeletePolicy {
  const AutoDeletePolicy._();

  static bool shouldDelete({
    required DateTime itemTimestamp,
    required bool isPinned,
    required int autoDeleteMinutes,
    required DateTime? activatedAt,
    required DateTime now,
  }) {
    if (isPinned || autoDeleteMinutes <= 0 || activatedAt == null) {
      return false;
    }
    if (!itemTimestamp.isAfter(activatedAt)) {
      return false;
    }
    return now.difference(itemTimestamp).inMinutes >= autoDeleteMinutes;
  }
}
