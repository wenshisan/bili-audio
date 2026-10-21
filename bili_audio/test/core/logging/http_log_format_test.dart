import 'package:bili_audio/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatQuery 脱敏登录字段并截断长值', () {
    final query = formatQuery({
      'keyword': '夜曲',
      'SESSDATA': 'secret-token',
      'bili_jct': 'jct',
      'note': 'x' * 100,
    });
    expect(query, contains('keyword=夜曲'));
    expect(query, contains('SESSDATA=***'));
    expect(query, contains('bili_jct=***'));
    expect(query, isNot(contains('secret-token')));
    expect(query, contains('…'));
  });

  test('summarizeBody 只保留 code、message 和数据形状', () {
    final summary = summarizeBody({
      'code': -412,
      'message': '请求过于频繁',
      'data': {
        'dash': {
          'audio': [
            {'id': 30232, 'baseUrl': 'https://cdn.example/a.m4s?deadline=1'},
          ],
        },
      },
    });
    expect(summary, contains('code=-412'));
    expect(summary, contains('message=请求过于频繁'));
    expect(summary, contains('data=map('));
    expect(summary, isNot(contains('cdn.example')));
    expect(summary, isNot(contains('deadline')));
  });
}
