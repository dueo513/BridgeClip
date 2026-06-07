class FirestoreRestCodec {
  static Map<String, dynamic> fields(Map<String, dynamic> values) {
    return {
      for (final entry in values.entries)
        entry.key: switch (entry.value) {
          String value => {'stringValue': value},
          bool value => {'booleanValue': value},
          DateTime value => {'timestampValue': value.toUtc().toIso8601String()},
          int value => {'integerValue': value.toString()},
          double value => {'doubleValue': value},
          _ => {'nullValue': null},
        },
    };
  }

  static Map<String, dynamic> fromFields(Map<String, dynamic>? fields) {
    final result = <String, dynamic>{};
    if (fields == null) return result;

    for (final entry in fields.entries) {
      final value = entry.value as Map<String, dynamic>;
      if (value.containsKey('stringValue')) {
        result[entry.key] = value['stringValue'] as String;
      } else if (value.containsKey('booleanValue')) {
        result[entry.key] = value['booleanValue'] as bool;
      } else if (value.containsKey('timestampValue')) {
        result[entry.key] = DateTime.parse(value['timestampValue'] as String);
      } else if (value.containsKey('integerValue')) {
        result[entry.key] = int.tryParse(value['integerValue'] as String) ?? 0;
      } else if (value.containsKey('doubleValue')) {
        result[entry.key] = (value['doubleValue'] as num).toDouble();
      }
    }

    return result;
  }
}
