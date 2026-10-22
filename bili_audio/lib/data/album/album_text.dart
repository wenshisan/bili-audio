import '../../core/utils/cover_url.dart';

/// 专辑介绍里的换行和简单 HTML 收成纯文本。
String? plainText(String? raw) {
  if (raw == null) return null;
  final text = raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  if (text.isEmpty) return null;
  return text.length > 2000 ? text.substring(0, 2000) : text;
}

int? _validYear(int year) {
  final max = DateTime.now().year + 1;
  if (year < 1900 || year > max) return null;
  return year;
}

/// 网易云的发行时间是毫秒时间戳。
int? yearFromMillis(num? ms) {
  if (ms == null || ms < 100000000000) return null;
  return _validYear(DateTime.fromMillisecondsSinceEpoch(ms.toInt()).year);
}

/// `2008-10-15` 或 ISO 日期里的年份。
int? yearFromDate(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) return _validYear(parsed.year);
  final match = RegExp(r'(?:19|20)\d{2}').firstMatch(trimmed);
  if (match == null) return null;
  return _validYear(int.parse(match.group(0)!));
}

/// 封面地址补成 https，避免播放页加载被系统拦住。
String? httpsCover(String? url) {
  final abs = absoluteCoverUrl(url);
  if (abs == null) return null;
  if (abs.startsWith('http://')) {
    return 'https://${abs.substring('http://'.length)}';
  }
  return abs;
}
