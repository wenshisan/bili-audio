import 'package:bili_audio/domain/title/fuzzy_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fuzzy = FuzzyMatcher();

  test('序号是干扰，0065. 洋葱和洋葱是同一首歌', () {
    expect(fuzzy.similarity('0065. 洋葱', '洋葱'), 1);
    expect(fuzzy.similarity('0065洋葱', '洋葱'), 1);
    expect(fuzzy.similarity('0151. 怎么好意思', '怎么好意思'), 1);
  });

  test('英文别名贴在中文名上仍算同一歌手', () {
    expect(fuzzy.similarity('Eric周兴哲', '周兴哲'), greaterThanOrEqualTo(0.9));
  });

  test('Live 尾巴不把同一首歌拆开', () {
    expect(fuzzy.similarity('以父之名 (Live)', '以父之名'), greaterThanOrEqualTo(0.92));
  });

  test('不同的歌保持低分', () {
    expect(fuzzy.similarity('洋葱', '稻香'), lessThan(0.5));
    expect(fuzzy.similarity('周杰伦', '五月天'), lessThan(0.5));
  });
}
