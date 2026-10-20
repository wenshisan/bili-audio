import 'package:flutter/material.dart';

/// 首页占位 (M0.4)，后续在 M6 实现完整布局 (底部导航 + 迷你播放栏)。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('哔哩哔哩音频播放器'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64),
            SizedBox(height: 16),
            Text('项目初始化完成', style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Text('M0 基础架构搭建完毕，后续功能开发中...'),
          ],
        ),
      ),
    );
  }
}
