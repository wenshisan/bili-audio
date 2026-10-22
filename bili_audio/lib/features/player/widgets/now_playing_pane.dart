import 'package:flutter/material.dart';

/// 大宽度右侧播放栏。A1 换成与播放页共用的控件。
class NowPlayingPane extends StatelessWidget {
  const NowPlayingPane({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      key: Key('now-playing-pane'),
    );
  }
}
