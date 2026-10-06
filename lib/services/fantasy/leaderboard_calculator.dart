/// Leaderboard Calculator — pure logic
/// Tie-breaker rules:
///   Match 1: Points → Alphabetical → Date → Time
///   Match 2+: Points → Previous Rank → Alphabetical → Time
///   Winner single (no shared rank)
class LeaderboardCalculator {
  /// Input: list of entries
  ///   Each: {
  ///     'userId', 'userName', 'totalPoints', 'previousRank',
  ///     'lastSubmittedAt' (DateTime, optional)
  ///   }
  /// Returns: same list, sorted & with 'rank' assigned (1-based, unique)
  static List<Map<String, dynamic>> rank({
    required List<Map<String, dynamic>> entries,
    required bool isFirstMatch,
  }) {
    final list = List<Map<String, dynamic>>.from(entries);

    list.sort((a, b) {
      // 1. Points DESC
      final pa = (a['totalPoints'] ?? 0) as int;
      final pb = (b['totalPoints'] ?? 0) as int;
      if (pa != pb) return pb.compareTo(pa);

      // 2. Previous rank ASC (Match 2+)
      if (!isFirstMatch) {
        final ra = (a['previousRank'] ?? 999999) as int;
        final rb = (b['previousRank'] ?? 999999) as int;
        if (ra != rb) return ra.compareTo(rb);
      }

      // 3. Alphabetical
      final na = (a['userName'] ?? '') as String;
      final nb = (b['userName'] ?? '') as String;
      final nameCmp = na.toLowerCase().compareTo(nb.toLowerCase());
      if (nameCmp != 0) return nameCmp;

      // 4. Time (earlier submission wins)
      final ta = a['lastSubmittedAt'] as DateTime?;
      final tb = b['lastSubmittedAt'] as DateTime?;
      if (ta != null && tb != null) {
        return ta.compareTo(tb);
      }
      return 0;
    });

    // Assign unique rank (1-based, no shared ranks)
    final List<Map<String, dynamic>> result = [];
    for (int i = 0; i < list.length; i++) {
      final entry = Map<String, dynamic>.from(list[i]);
      entry['previousRank'] = entry['rank'] ?? 0;
      entry['rank'] = i + 1; // 1-based unique
      result.add(entry);
    }
    return result;
  }

  /// Find winner (top 1)
  static Map<String, dynamic>? winner(
    List<Map<String, dynamic>> rankedList,
  ) {
    if (rankedList.isEmpty) return null;
    return rankedList.first;
  }
}