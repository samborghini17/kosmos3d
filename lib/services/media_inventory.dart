/// Expand documented GoPro photo groups. The group `s` is a member count,
/// whereas a standalone entry's `s` is a byte length.
List<Map<String, dynamic>> expandMediaEntries(List<dynamic> entries) {
  final result = <String, Map<String, dynamic>>{};
  for (final raw in entries) {
    final entry = Map<String, dynamic>.from(raw as Map);
    final filename = entry['n']?.toString() ?? '';
    if (!RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(filename) ||
        filename == '.' ||
        filename == '..') {
      throw const FormatException('Invalid camera media filename');
    }
    final members = <Map<String, dynamic>>[];
    if (entry.containsKey('g')) {
      final first = int.tryParse('${entry['b']}'),
          last = int.tryParse('${entry['l']}');
      final match = RegExp(
        r'^(.*?)(\d{4})(\.[A-Za-z0-9]+)$',
      ).firstMatch(filename);
      if (match == null ||
          first == null ||
          last == null ||
          first < 0 ||
          last < first ||
          last > 9999 ||
          int.parse(match[2]!) != first ||
          !['b', 'c', 'n', 't'].contains(entry['t'])) {
        throw FormatException(
          'Unsupported grouped media: $filename. Import this group with an SD-card reader.',
        );
      }
      final missing = (entry['m'] as List? ?? [])
          .map((v) => int.tryParse('$v'))
          .toSet();
      for (var i = first; i <= last; i++) {
        if (!missing.contains(i)) {
          members.add({
            ...entry,
            'n': '${match[1]}${i.toString().padLeft(4, '0')}${match[3]}',
            's': 0,
          });
        }
      }
      final count = int.tryParse('${entry['s']}');
      if (count != null && count != members.length) {
        throw FormatException('Incomplete media group inventory: $filename');
      }
    } else {
      members.add(entry);
    }
    for (final member in members) {
      result[member['n'] as String] = member;
      if ('${member['raw']}' == '1' &&
          (member['n'] as String).toLowerCase().endsWith('.jpg')) {
        final rawName = (member['n'] as String).replaceFirst(
          RegExp(r'\.[^.]+$'),
          '.GPR',
        );
        result[rawName] = {...member, 'n': rawName, 's': 0};
      }
    }
  }
  return result.values.toList();
}
