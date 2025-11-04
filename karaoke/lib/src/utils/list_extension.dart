/// Adds deep equality checks to [List], with optional ordering semantics.
extension ListExtension<T> on List<T> {
  /// Returns `true` if this list and [other] are equal under the
  /// specified [orderMatters] rules:
  ///
  /// - If `orderMatters == true` (default), both lists must have the same
  ///   length and each `this[i] == other[i]`.
  /// - If `orderMatters == false`, the lists are treated as multisets:
  ///   element counts must match, but order is ignored.
  ///
  /// Throws nothing; works in O(n) time for ordered checks and O(n)
  /// time & space for unordered checks.
  ///
  /// Example:
  /// ```dart
  /// [1, 2, 3].isEqual([1, 2, 3]);            // true
  /// [1, 2, 3].isEqual([3, 2, 1], orderMatters: false); // true
  /// ```
  bool isEqual(
      List<T> other, {
        bool orderMatters = true,
      }) {
    if (identical(this, other)) return true;
    if (length != other.length) return false;

    if (orderMatters) {
      // Element-by-element deep comparison
      for (var i = 0; i < length; i++) {
        if (this[i] != other[i]) return false;
      }
      return true;
    }

    // Unordered: frequency map approach
    final counts = <T, int>{};
    for (var e in this) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    for (var e in other) {
      final c = counts[e];
      if (c == null || c == 0) return false;
      counts[e] = c - 1;
    }
    return true;
  }

  /// Returns `true` if this list and [other] are _not_ equal under
  /// the same [orderMatters] rules.
  ///
  /// Example:
  /// ```dart
  /// ['a', 'b'].isDifferent(['b', 'a']);            // true
  /// ['a', 'b'].isDifferent(['b', 'a'], orderMatters: false); // false
  /// ```
  bool isDifferent(
      List<T> other, {
        bool orderMatters = true,
      }) =>
      !isEqual(other, orderMatters: orderMatters);
}
