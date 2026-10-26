import 'dart:math';

import '../text_normalization.dart';
import 'title_cleaner.dart';

/// 模糊匹配。
///
/// 先丢掉分 P 序号、音质和版本尾巴，再比较剩下的歌名或歌手。
/// `0065. 洋葱` 和 `洋葱`、`Eric周兴哲` 和 `周兴哲` 视为同一段文字。
class FuzzyMatcher {
  const FuzzyMatcher();

  /// 返回 0-1。两边折成同一骨架时为 1。
  double similarity(String a, String b) {
    final left = _fold(a);
    final right = _fold(b);
    if (left.isEmpty || right.isEmpty) return 0;
    if (left == right) return 1;

    final scores = <double>[
      _levenshteinSimilarity(left, right),
      _jaccard(_tokenize(left), _tokenize(right)),
      _containment(left, right),
    ];
    if (_hasChinese(left) || _hasChinese(right)) {
      if (_sameCjkCore(left, right)) scores.add(0.96);
      scores.add(_levenshteinSimilarity(toPinyin(left), toPinyin(right)));
    }
    return scores.reduce(max);
  }

  /// 抽出可比文本：宽松清洗后再剥掉粘在歌名前面的序号。
  String _fold(String raw) {
    final loose = TitleCleaner.parseLoose(raw).name.trim();
    final base = loose.isEmpty ? raw : loose;
    var text = normalizeForMatch(base);
    final stripped = text.replaceFirst(RegExp(r'^\d{1,4}(?=\S)'), '');
    if (stripped.isNotEmpty &&
        RegExp(r'[\u4e00-\u9fffa-z]').hasMatch(stripped)) {
      text = stripped;
    }
    return text;
  }

  /// 中文核相同，多出来的只是短英文别名或数字。
  bool _sameCjkCore(String a, String b) {
    final coreA = a.replaceAll(RegExp(r'[a-z0-9]+'), '');
    final coreB = b.replaceAll(RegExp(r'[a-z0-9]+'), '');
    if (coreA.length < 2 || coreA != coreB) return false;
    return _ignorable(a.replaceAll(coreA, '')) &&
        _ignorable(b.replaceAll(coreB, ''));
  }

  bool _ignorable(String extra) {
    if (extra.isEmpty || RegExp(r'^\d+$').hasMatch(extra)) return true;
    if (_versionExtra.hasMatch(extra)) return true;
    return RegExp(r'^[a-z]{1,8}$').hasMatch(extra);
  }

  double _containment(String a, String b) {
    final shorter = a.length <= b.length ? a : b;
    final longer = a.length <= b.length ? b : a;
    if (shorter.length < 2 || !longer.contains(shorter)) return 0;
    final extra = longer
        .replaceFirst(shorter, '')
        .replaceAll(RegExp(r'[\s\d._+\-]+'), '');
    if (extra.isEmpty || _versionExtra.hasMatch(extra) || _ignorable(extra)) {
      return 0.92;
    }
    return 0;
  }

  static final _versionExtra = RegExp(
    r'^(?:live|remix|cover|inst|instrumental|acoustic|demo|ost|mv|pv|tv|ver|version|hires|flac|dsd|ape|wav|official|翻唱|现场|演唱会|钢琴|吉他|伴奏|纯音乐|女声|男声|烟嗓|完整|原版|歌词)+$',
    caseSensitive: false,
  );

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final union = a.union(b).length;
    if (union == 0) return 0;
    return a.intersection(b).length / union;
  }

  Set<String> _tokenize(String text) {
    final tokens = <String>{};
    final buffer = StringBuffer();
    for (final char in text.runes) {
      final str = String.fromCharCode(char);
      if (_isChinese(str)) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(str);
      } else if (RegExp(r'[a-z0-9]').hasMatch(str)) {
        buffer.write(str);
      } else if (buffer.isNotEmpty) {
        tokens.add(buffer.toString());
        buffer.clear();
      }
    }
    if (buffer.isNotEmpty) tokens.add(buffer.toString());
    return tokens;
  }

  double _levenshteinSimilarity(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    final maxLen = max(a.length, b.length);
    return max(0.0, 1 - _levenshteinDistance(a, b) / maxLen);
  }

  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );
    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }
    return matrix[a.length][b.length];
  }

  bool _isChinese(String char) {
    final code = char.runes.first;
    return code >= 0x4e00 && code <= 0x9fff;
  }

  bool _hasChinese(String text) {
    return text.runes.any((code) => code >= 0x4e00 && code <= 0x9fff);
  }
}
