import 'package:bili_audio/core/utils/cover_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('协议相对封面补 https，绝对地址保持不变', () {
    expect(
      absoluteCoverUrl('//i0.hdslb.com/bfs/archive/a.jpg'),
      'https://i0.hdslb.com/bfs/archive/a.jpg',
    );
    expect(
      absoluteCoverUrl('https://i0.hdslb.com/a.jpg'),
      'https://i0.hdslb.com/a.jpg',
    );
  });

  test('空值和没有主机的地址返回 null', () {
    expect(absoluteCoverUrl(null), isNull);
    expect(absoluteCoverUrl('  '), isNull);
    expect(absoluteCoverUrl('not a url'), isNull);
  });
}
