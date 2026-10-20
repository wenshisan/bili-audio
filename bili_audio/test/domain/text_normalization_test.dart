import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/domain/text_normalization.dart';

void main() {
  group('normalizeForMatch', () {
    test('全角→半角', () {
      expect(normalizeForMatch('Ａ１２３'), 'a123');
      expect(normalizeForMatch('ａｂｃ'), 'abc');
      expect(normalizeForMatch('（测试）'), '测试');
    });

    test('小写', () {
      expect(normalizeForMatch('ABC'), 'abc');
      expect(normalizeForMatch('TeSt'), 'test');
    });

    test('折叠空白', () {
      expect(normalizeForMatch('a  b\tc\nd'), 'a b c d');
      expect(normalizeForMatch('  trim  '), 'trim');
    });

    test('去标点', () {
      expect(normalizeForMatch('Hello, World!'), 'hello world');
      expect(normalizeForMatch('测试。。。'), '测试');
      expect(normalizeForMatch('【标题】'), '标题');
      expect(normalizeForMatch('歌名 - 歌手'), '歌名  歌手');
    });

    test('中日英混排', () {
      expect(
        normalizeForMatch('周杰伦 - 七里香（Hi-Res）'),
        '周杰伦  七里香hires',
      );
    });

    test('emoji 保留', () {
      expect(normalizeForMatch('Test 🎵'), 'test 🎵');
    });

    test('全角符号', () {
      expect(normalizeForMatch('《歌名》、「副标题」'), '歌名副标题');
    });
  });

  group('normalizeForDisplay', () {
    test('全角→半角', () {
      expect(normalizeForDisplay('Ａ１２３'), 'A123');
      expect(normalizeForDisplay('（测试）'), '(测试)');
    });

    test('折叠空白', () {
      expect(normalizeForDisplay('a  b\tc'), 'a b c');
    });

    test('保留标点', () {
      expect(normalizeForDisplay('Hello, World!'), 'Hello, World!');
      expect(normalizeForDisplay('【标题】'), '【标题】');
    });

    test('保留大小写', () {
      expect(normalizeForDisplay('TeSt'), 'TeSt');
    });

    test('不做繁简转换 (保持原文)', () {
      // 注: 当前未实现繁→简，此测试验证"不转换"是正确行为
      expect(normalizeForDisplay('測試'), '測試');
    });
  });

  group('toPinyin', () {
    test('中文转拼音', () {
      final result = toPinyin('周杰伦');
      expect(result, 'zhoujielun');
    });

    test('中英混合', () {
      final result = toPinyin('周杰伦 Jay');
      // lpinyin 会保留非中文字符
      expect(result.replaceAll(' ', ''), contains('zhoujielun'));
      expect(result.toLowerCase(), contains('jay'));
    });

    test('非中文保留', () {
      final result = toPinyin('Test123');
      expect(result.toLowerCase(), 'test123');
    });

    test('无声调', () {
      final result = toPinyin('你好');
      expect(result, isNot(contains(RegExp(r'[0-9]'))));
    });
  });
}
