import 'package:flutter/foundation.dart';
import 'dialogue_block.dart';

// ============================================================
// 转写详情 Fake 数据源 (仅 debug 模式加载)
// ============================================================
class FakeTranscriptionDataSource {
  static List<DialogueBlock> getDemoDialogues() {
    if (!kDebugMode) return [];
    return [
      DialogueBlock(
        index: 0,
        speaker: '发言人1',
        time: 1,
        timeText: '00:00:01',
        text:
            '好，大家都到齐了，我们开始吧。今天核心就一个事，定一下‘智能水杯’的上市时间。原计划是9月1日，但研发那边好像有些阻力。李莉，你先说说情况？',
        translation: '',
      ),
      DialogueBlock(
        index: 1,
        speaker: '发言人2',
        time: 9,
        timeText: '00:00:09',
        text:
            '各位。确实有困难。核心的 hydration tracking（水合追踪）算法最近测试发现，在高温环境下准确度会下降10%。我们可能需要额外两周时间来优化。',
        translation: '',
      ),
      DialogueBlock(
        index: 2,
        speaker: '发言人1',
        time: 25,
        timeText: '00:00:25',
        text:
            '两周？这麻烦大了！我们所有的预热物料、KOL档期都压在9月初了。推迟两周，就直接撞上竞品B的发布会了，效果会大打折扣。能不能先上线，后续再通过OTA升级算法？',
        translation: '',
      ),
      DialogueBlock(
        index: 3,
        speaker: '发言人2',
        time: 32,
        timeText: '00:00:32',
        text: '我理解你的压力。但这是核心卖点，如果首发评测翻车，口碑就完了。',
        translation: '',
      ),
      DialogueBlock(
        index: 4,
        speaker: '发言人1',
        time: 36,
        timeText: '00:00:36',
        text: '两周？这麻烦大了！我们所有的预热物料、KOL档期都压在9月初了。',
        translation: '',
      ),
      DialogueBlock(
        index: 5,
        speaker: '发言人3',
        time: 150,
        timeText: '00:02:30',
        text:
            '我同意他的看法，质量是首要任务。同时，我们也应该关注市场竞争，可能需要进行一些用户调研，以便了解他们的需求。',
        translation: '',
      ),
      DialogueBlock(
        index: 6,
        speaker: '发言人1',
        time: 225,
        timeText: '00:03:45',
        text:
            '非常感谢大家的意见。我建议我们设定一个明确的时间表，以确保每个阶段都有反馈，并且能够及时调整策略。',
        translation: '',
      ),
    ];
  }
}
