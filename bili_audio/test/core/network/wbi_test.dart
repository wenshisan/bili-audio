import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/core/network/wbi.dart';

void main() {
  group('Wbi', () {
    test('从 URL 提取 key', () {
      const imgUrl =
          'https://i0.hdslb.com/bfs/wbi/7cd084941338484aae1ad9425b84077c.png';
      const subUrl =
          'https://i0.hdslb.com/bfs/wbi/4932caff0ff746eab6f01bf08b70ac45.png';

      expect(Wbi.keyFromUrl(imgUrl), '7cd084941338484aae1ad9425b84077c');
      expect(Wbi.keyFromUrl(subUrl), '4932caff0ff746eab6f01bf08b70ac45');
    });

    test('mixinKey 生成 (已知向量)', () {
      // 已知测试向量
      const imgKey = '7cd084941338484aae1ad9425b84077c';
      const subKey = '4932caff0ff746eab6f01bf08b70ac45';

      final mixin = Wbi.mixinKey(imgKey, subKey);

      // 按混淆表前 32 位
      expect(mixin.length, 32);
      expect(mixin, 'ea1db124af3c7062474693fa704f4ff8');
    });

    test('w_rid 已知向量 (bilibili-API-collect)', () {
      final signed = Wbi.sign(
        {'foo': '114', 'bar': '514', 'zab': '1919810'},
        'ea1db124af3c7062474693fa704f4ff8',
        wts: 1702204169,
      );
      expect(signed['w_rid'], '8f6f2b5b3d485fe1886cec6a0be8c5d4');
    });

    test('签名参数', () {
      const mixinKey = '9d9c61c3f3a36c9c4b6b8c1e3f3d6c5e';
      final params = {'foo': 'bar', 'test': '测试'};
      const wts = 1234567890;

      final signed = Wbi.sign(params, mixinKey, wts: wts);

      expect(signed['foo'], 'bar');
      expect(signed['test'], '测试');
      expect(signed['wts'], '1234567890');
      expect(signed['w_rid'], isNotEmpty);

      // 验证 w_rid 格式 (32位 md5)
      expect(signed['w_rid'], hasLength(32));
      expect(RegExp(r'^[a-f0-9]{32}$').hasMatch(signed['w_rid']!), true);
    });

    test('过滤非法字符', () {
      const mixinKey = 'testkey';
      final params = {'key': "test!'()*value"};
      const wts = 1234567890;

      final signed = Wbi.sign(params, mixinKey, wts: wts);

      // !'()* 应被过滤
      expect(signed['key'], 'testvalue');
    });

    test('参数排序', () {
      const mixinKey = 'testkey';
      final params = {'z': '3', 'a': '1', 'm': '2'};
      const wts = 1234567890;

      final signed = Wbi.sign(params, mixinKey, wts: wts);

      // 签名包含所有参数
      expect(signed.keys, containsAll(['a', 'm', 'z', 'wts', 'w_rid']));
    });
  });
}
