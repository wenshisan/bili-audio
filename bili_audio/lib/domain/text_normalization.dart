import 'package:lpinyin/lpinyin.dart';

/// 文本归一化工具 (M1.2)
///
/// 用于标题清洗和歌词匹配的文本预处理。

/// 全角→半角映射 (仅用于 normalizeForMatch)
const _fullwidthToHalfwidthForMatch = {
  '０': '0', '１': '1', '２': '2', '３': '3', '４': '4',
  '５': '5', '６': '6', '７': '7', '８': '8', '９': '9',
  'Ａ': 'A', 'Ｂ': 'B', 'Ｃ': 'C', 'Ｄ': 'D', 'Ｅ': 'E',
  'Ｆ': 'F', 'Ｇ': 'G', 'Ｈ': 'H', 'Ｉ': 'I', 'Ｊ': 'J',
  'Ｋ': 'K', 'Ｌ': 'L', 'Ｍ': 'M', 'Ｎ': 'N', 'Ｏ': 'O',
  'Ｐ': 'P', 'Ｑ': 'Q', 'Ｒ': 'R', 'Ｓ': 'S', 'Ｔ': 'T',
  'Ｕ': 'U', 'Ｖ': 'V', 'Ｗ': 'W', 'Ｘ': 'X', 'Ｙ': 'Y', 'Ｚ': 'Z',
  'ａ': 'a', 'ｂ': 'b', 'ｃ': 'c', 'ｄ': 'd', 'ｅ': 'e',
  'ｆ': 'f', 'ｇ': 'g', 'ｈ': 'h', 'ｉ': 'i', 'ｊ': 'j',
  'ｋ': 'k', 'ｌ': 'l', 'ｍ': 'm', 'ｎ': 'n', 'ｏ': 'o',
  'ｐ': 'p', 'ｑ': 'q', 'ｒ': 'r', 'ｓ': 's', 'ｔ': 't',
  'ｕ': 'u', 'ｖ': 'v', 'ｗ': 'w', 'ｘ': 'x', 'ｙ': 'y', 'ｚ': 'z',
  '　': ' ', // 全角空格
  '（': '(', '）': ')', '［': '[', '］': ']',
  '｛': '{', '｝': '}', '《': '<', '》': '>',
  '！': '!', '？': '?', '：': ':', '；': ';',
  '，': ',', '。': '.', '、': ',', '・': '·',
  '～': '~', '－': '-', '＿': '_', '／': '/',
  '＠': '@', '＃': '#', '＄': '\$', '％': '%',
  '＾': '^', '＆': '&', '＊': '*', '＋': '+', '＝': '=',
};

/// 全角→半角映射 (用于 normalizeForDisplay, 仅转换字母数字和括号)
const _fullwidthToHalfwidthForDisplay = {
  '０': '0', '１': '1', '２': '2', '３': '3', '４': '4',
  '５': '5', '６': '6', '７': '7', '８': '8', '９': '9',
  'Ａ': 'A', 'Ｂ': 'B', 'Ｃ': 'C', 'Ｄ': 'D', 'Ｅ': 'E',
  'Ｆ': 'F', 'Ｇ': 'G', 'Ｈ': 'H', 'Ｉ': 'I', 'Ｊ': 'J',
  'Ｋ': 'K', 'Ｌ': 'L', 'Ｍ': 'M', 'Ｎ': 'N', 'Ｏ': 'O',
  'Ｐ': 'P', 'Ｑ': 'Q', 'Ｒ': 'R', 'Ｓ': 'S', 'Ｔ': 'T',
  'Ｕ': 'U', 'Ｖ': 'V', 'Ｗ': 'W', 'Ｘ': 'X', 'Ｙ': 'Y', 'Ｚ': 'Z',
  'ａ': 'a', 'ｂ': 'b', 'ｃ': 'c', 'ｄ': 'd', 'ｅ': 'e',
  'ｆ': 'f', 'ｇ': 'g', 'ｈ': 'h', 'ｉ': 'i', 'ｊ': 'j',
  'ｋ': 'k', 'ｌ': 'l', 'ｍ': 'm', 'ｎ': 'n', 'ｏ': 'o',
  'ｐ': 'p', 'ｑ': 'q', 'ｒ': 'r', 'ｓ': 's', 'ｔ': 't',
  'ｕ': 'u', 'ｖ': 'v', 'ｗ': 'w', 'ｘ': 'x', 'ｙ': 'y', 'ｚ': 'z',
  '　': ' ', // 全角空格
  '（': '(', '）': ')',
};

/// 标点符号集合 (用于 normalizeForMatch 删除)
final _punctuationPattern = RegExp(
  r'''[!"#$%&'()*+,\-./:;<=>?@\[\\\]^_`{|}~。，、；：？！…—·「」『』【】《》〈〉""''（）［］｛｝]''',
);

/// 全角→半角转换 (用于匹配)
String _toHalfwidthForMatch(String text) {
  final buffer = StringBuffer();
  for (final char in text.runes) {
    final str = String.fromCharCode(char);
    buffer.write(_fullwidthToHalfwidthForMatch[str] ?? str);
  }
  return buffer.toString();
}

/// 全角→半角转换 (用于显示)
String _toHalfwidthForDisplay(String text) {
  final buffer = StringBuffer();
  for (final char in text.runes) {
    final str = String.fromCharCode(char);
    buffer.write(_fullwidthToHalfwidthForDisplay[str] ?? str);
  }
  return buffer.toString();
}

/// 折叠空白: 将连续空白字符 (空格/制表符/换行) 替换为单个空格，并去除首尾空白
String _foldWhitespace(String text) {
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// 用于匹配的文本归一化 (M1.2)
///
/// 步骤:
/// 1. 全角→半角
/// 2. 繁→简 (TODO: 需要从 OpenCC 词典生成映射表，暂时跳过)
/// 3. 小写
/// 4. 折叠空白
/// 5. 去标点
String normalizeForMatch(String text) {
  var result = _toHalfwidthForMatch(text);
  // TODO: 繁→简转换 (D6: 构建期从 OpenCC 词典生成 assets/dict/t2s.txt)
  result = result.toLowerCase();
  result = _foldWhitespace(result);
  result = result.replaceAll(_punctuationPattern, '');
  return result;
}

/// 用于显示的文本归一化 (M1.2)
///
/// 只做全角→半角与空白折叠，**不做**繁简转换 (PRD: 显示保持原文)。
String normalizeForDisplay(String text) {
  var result = _toHalfwidthForDisplay(text);
  result = _foldWhitespace(result);
  return result;
}

/// 转拼音 (M1.2)
///
/// 使用 lpinyin 无声调拼音，非中文原样保留。
/// 示例: "周杰伦 Jay" → "zhoujielun jay"
String toPinyin(String text) {
  // 无声调格式直接输出纯字母，非中文字符原样保留
  final pinyin = PinyinHelper.getPinyinE(
    text,
    separator: '',
    defPinyin: '',
    format: PinyinFormat.WITHOUT_TONE,
  );
  return pinyin.toLowerCase();
}

/// 拼音首字母，非中文原样保留并转为小写。
///
/// 示例: "周杰伦" → "zjl"
String toPinyinInitials(String text) {
  return PinyinHelper.getShortPinyin(text).toLowerCase();
}
