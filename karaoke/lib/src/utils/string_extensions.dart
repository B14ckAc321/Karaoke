/// A collection of extensions on [String] for common sanitization,
/// casing transformations, and computing string similarity.
extension StringExtension on String {
  // ------------------ Sanitization -------------------

  /// Trims whitespace, converts to lowercase, replaces accented
  /// characters with their unaccented equivalents, and strips
  /// all non-alphanumeric characters.
  ///
  /// This is useful for normalizing user input or for
  /// case‐ and diacritic‐insensitive comparisons.
  ///
  /// Example:
  /// ```dart
  /// ' Café Déjà Vu! '.sanitize(); // 'cafedejavu'
  /// ```
  String sanitize() {
    return trim().toLowerCase() // Remove whitespace & lowercase
        .replaceAll(RegExp('[àáâãäå]'), 'a')
        .replaceAll(RegExp('æ'), 'ae')
        .replaceAll(RegExp('ç'), 'c')
        .replaceAll(RegExp('[èéêë]'), 'e')
        .replaceAll(RegExp('[ìíîï]'), 'i')
        .replaceAll(RegExp('ñ'), 'n')
        .replaceAll(RegExp('[òóôõöø]'), 'o')
        .replaceAll(RegExp('œ'), 'oe')
        .replaceAll(RegExp('[ùúûü]'), 'u')
        .replaceAll(RegExp('[ýÿ]'), 'y')
        .replaceAll(RegExp('[^a-z0-9]'), ''); // Remove non-alphanumerics
  }

  // ------------------ Numeric parsing -------------------

  /// Trims whitespace and lowercases, then replaces:
  /// - commas with decimal points,
  /// - removes apostrophes, underscores, and spaces.
  ///
  /// Useful for cleaning up locale‐specific number strings.
  ///
  /// Example:
  /// ```dart
  /// "1 234,56".numberify(); // "1234.56"
  /// ```
  String numberify() {
    return trim().toLowerCase()
        .replaceAll(',', '.')
        .replaceAll("'", '')
        .replaceAll('_', '')
        .replaceAll(' ', '');
  }

  // ------------------ Capitalization -------------------

  /// Returns the string with only its first character uppercased.
  ///
  /// If the string is empty (after trimming), returns an empty string.
  ///
  /// Example:
  /// ```dart
  /// 'hello'.capitalizeFirstLetter(); // 'Hello'
  /// ```
  String capitalizeFirstLetter() {
    final t = trim();
    if (t.isEmpty) return '';
    return '${t[0].toUpperCase()}${t.substring(1)}';
  }

  /// Returns only the first character of the trimmed string,
  /// uppercased. If the string is empty, throws a RangeError.
  ///
  /// Example:
  /// ```dart
  /// 'world'.capitalizeAndCut(); // 'W'
  /// ```
  String capitalizeAndCut() {
    final t = trim();
    if (t.isEmpty) throw RangeError('String is empty');
    return t[0].toUpperCase();
  }

  // ------------------ Case transformations -------------------

  static final RegExp _upperAlphaRegex = RegExp(r'[A-Z]');
  static final Set<String> _symbolSet = {' ', '.', '/', '_', '\\', '-'};

  /// Splits the string into “words” based on capitalization
  /// transitions and separator symbols.
  List<String> get _words {
    final words = <String>[];
    final buffer = StringBuffer();
    final isAllCaps = this.toUpperCase() == this;

    for (var i = 0; i < length; i++) {
      final char = this[i];
      final next = i + 1 < length ? this[i + 1] : null;

      if (_symbolSet.contains(char)) continue;

      buffer.write(char);

      final isEnd = next == null ||
          (_upperAlphaRegex.hasMatch(next) && !isAllCaps) ||
          _symbolSet.contains(next);

      if (isEnd) {
        words.add(buffer.toString());
        buffer.clear();
      }
    }
    return words;
  }

  /// Generic transformation of words into a joined string.
  ///
  /// [wordTransform] is applied to each piece, then joined
  /// with [separator].
  String _transformCase({
    required String Function(String word) wordTransform,
    String separator = '',
  }) {
    return _words.map(wordTransform).join(separator);
  }

  /// Lower Camel Case (e.g. "fooBarBaz").
  String get camelCase => _transformCase(
    wordTransform: (word) => word == _words.first
        ? word.toLowerCase()
        : _upperCaseFirstLetter(word),
  );

  /// UPPER_SNAKE_CASE.
  String get constantCase => _transformCase(
    wordTransform: (word) => word.toUpperCase(),
    separator: '_',
  );

  /// Sentence case (e.g. "Foo bar baz").
  String get sentenceCase => _transformCase(
    wordTransform: (word) => word == _words.first
        ? _upperCaseFirstLetter(word)
        : word.toLowerCase(),
    separator: ' ',
  );

  /// lower_snake_case.
  String get snakeCase => _transformCase(
    wordTransform: (word) => word.toLowerCase(),
    separator: '_',
  );

  /// dot.case (e.g. "foo.bar.baz").
  String get dotCase => _transformCase(
    wordTransform: (word) => word.toLowerCase(),
    separator: '.',
  );

  /// param-case (kebab-case, e.g. "foo-bar-baz").
  String get paramCase => _transformCase(
    wordTransform: (word) => word.toLowerCase(),
    separator: '-',
  );

  /// path/case (e.g. "foo/bar/baz").
  String get pathCase => _transformCase(
    wordTransform: (word) => word.toLowerCase(),
    separator: '/',
  );

  /// PascalCase (e.g. "FooBarBaz").
  String get pascalCase => _transformCase(
    wordTransform: _upperCaseFirstLetter,
  );

  /// Header-Case (e.g. "Foo-Bar-Baz").
  String get headerCase => _transformCase(
    wordTransform: _upperCaseFirstLetter,
    separator: '-',
  );

  /// Title Case (e.g. "Foo Bar Baz").
  String get titleCase => _transformCase(
    wordTransform: _upperCaseFirstLetter,
    separator: ' ',
  );

  /// Uppercases just the first letter of [word], lowercasing the rest.
  String _upperCaseFirstLetter(String word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  // ------------------ Levenshtein Distance -------------------

  /// Computes the Levenshtein distance (edit distance) between this string
  /// and [other]. The distance is the minimum number of single-character
  /// edits (insertions, deletions, or substitutions) required to change
  /// one string into the other.
  ///
  /// Uses a dynamic programming approach with O(n×m) time and O(min(n, m))
  /// space, where n and m are the lengths of the two strings.
  ///
  /// Example:
  /// ```dart
  /// 'kitten'.levenshteinDistance('sitting'); // returns 3
  /// ```
  ///
  /// See also:
  /// * [https://en.wikipedia.org/wiki/Levenshtein_distance]
  int levenshteinDistance(String other) {
    final s = this;
    final n = s.length;
    final m = other.length;

    // If one is empty, distance is the length of the other
    if (n == 0) return m;
    if (m == 0) return n;

    // Ensure we use O(min(n, m)) space: iterate on the shorter string
    if (n < m) {
      // swap to ensure n >= m
      return other.levenshteinDistance(s);
    }

    // Previous and current row of distances
    var previous = List<int>.generate(m + 1, (j) => j);
    var current = List<int>.filled(m + 1, 0);

    for (var i = 1; i <= n; i++) {
      current[0] = i;
      for (var j = 1; j <= m; j++) {
        final cost = s[i - 1] == other[j - 1] ? 0 : 1;
        current[j] = [
          previous[j] + 1,       // deletion
          current[j - 1] + 1,    // insertion
          previous[j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
      // swap rows for next iteration
      final temp = previous;
      previous = current;
      current = temp;
    }

    return previous[m];
  }
}
