import 'package:flutter/foundation.dart';
import 'ai_models.dart';

// ============================================================
// Ask AI Fake 数据源 (仅 debug 模式加载)
// ============================================================
class FakeAiDataSource {
  static List<AiQuickPrompt> getQuickPrompts() {
    if (!kDebugMode) return [];
    return const [
      AiQuickPrompt(
        id: 'p1',
        title: '下次开会需要准备什么？',
        desc: '基于 5月6日 产品组会纪要整理行动项和待办任务',
        query: '根据5月6日的产品组会，总结下周我需要准备什么？',
      ),
      AiQuickPrompt(
        id: 'p2',
        title: '关于温控的设计讨论记录下？',
        desc: '提炼会议中关于设备发热量、A/B测试和导热片的决策',
        query: '关于温控的设计讨论记录下？',
      ),
      AiQuickPrompt(
        id: 'p3',
        title: '总结最近的反馈？',
        desc: '汇总近期产品测试中发现的用户体验阻力和核心性能问题',
        query: '总结最近几场会议中提到的用户反馈与体验阻力？',
      ),
    ];
  }

  static List<AiDialogue> getCitedDialogues() {
    if (!kDebugMode) return [];
    return const [
      AiDialogue(
        speaker: '李莉 (产品经理)',
        timeText: '00:00:12',
        text:
            '针对本次温度控制与功耗优化的设计，我们已经在主控IC周围部署了高阻燃散热片，但是由于本地降噪算法（面对面模式等）和 AI 个性化推荐在设备端高频运转，整机温度上升比较快，需要寻找更高效 of 导热方案。',
      ),
      AiDialogue(
        speaker: '王总 (技术总监)',
        timeText: '00:00:45',
        text:
            '李莉，温控设计在 A/B 测试中表现如何？散热片的材料换成石墨烯试过吗？',
      ),
      AiDialogue(
        speaker: '李莉 (产品经理)',
        timeText: '00:01:12',
        text:
            '试过了。我们在 A/B 测试中，方案 A 采用的是传统的导热硅脂，方案 B 升级成了 0.1mm 厚度的石墨烯导热片。测试结果显示，方案 B 的散热效率提升了 12.5%，整机表面最高温降了 2.5℃。这是一个非常明显的进步。',
      ),
      AiDialogue(
        speaker: '王总 (技术总监)',
        timeText: '00:01:50',
        text:
            '很好，那就敲定方案 B。但是我们的获客成本（CAC）目前还是偏高的，温控结构改进要在下周前给出结构打样，不能拖慢 9月1日 智能水杯的上市节奏。推荐代码也要在端午节前上线，给运营做裂变活动。',
      ),
    ];
  }

  static const AiCitedFile citedFile = AiCitedFile(
    id: 'rec_06',
    title: '05-06 产品会：用户增长策略与方案汇报',
    dateText: '5月6日 09:22',
    timeText: '56分钟',
    sizeText: '5.2M',
    durationSec: 3360,
  );

  static List<AiSelectableFile> getSelectableFiles() {
    if (!kDebugMode) return [];
    return const [
      AiSelectableFile(
        id: 'rec_01',
        title: '新录音2026-05-08 21:22:23',
        dateText: '今天 21:22',
        timeText: '25分钟',
      ),
      AiSelectableFile(
        id: 'rec_03',
        title: '新录音2026-05-06 21:22:23',
        dateText: '5月6日 21:22',
        timeText: '136分钟',
      ),
      AiSelectableFile(
        id: 'rec_05',
        title: '05-06 产品组会：用户增长测试与方案研讨',
        dateText: '5月6日 09:22',
        timeText: '56分钟',
      ),
      AiSelectableFile(
        id: 'rec_06',
        title: '05-06 产品会：用户增长策略与方案汇报',
        dateText: '5月6日 09:22',
        timeText: '56分钟',
      ),
    ];
  }
}
