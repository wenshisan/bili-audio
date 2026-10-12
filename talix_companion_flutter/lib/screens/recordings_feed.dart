import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../viewmodels/device_model.dart';
import '../viewmodels/recordings_feed_viewmodel.dart';
import '../widgets/device_info_widgets.dart';
import 'transcription_detail_screen.dart';

// ============================================================
// 文件管理 - 设备储存列表 (MVVM View)
// 对齐 Figma「Talix AI Device UI」669:3988
//
// PC 布局 (800 宽内容区居中):
//   669:4058  面包屑  「Talix AI Note › 文件管理」16px, 距顶 32
//   669:4047  Tabs    设备储存 (绿色 Bold + 24×2 下划线) / 主机储存, 距顶 88
//   669:4052  储存卡  208 宽, 右上角, 设备名 + 用量 + 2px 进度条
//   669:4002  表格    文件名(fill) / 日期时间(160) / 大小(56) / 操作(64)
//                     表头 12px #999999, 行 14px, 行高 padding 16/8, 分割线 #E9E9E9
// ============================================================
class RecordingsFeedScreen extends StatefulWidget {
  /// 真实设备序列号 (deviceSN)。传 null 时按「全部文件」加载。
  /// 对齐左侧导航「文件」分组下动态生成的真实设备子项。
  final String? deviceSN;
  /// 面包屑/储存卡要显示的设备名。为空时回退到全局 [DeviceModel.deviceName]。
  final String? deviceName;
  const RecordingsFeedScreen({super.key, this.deviceSN, this.deviceName});

  @override
  State<RecordingsFeedScreen> createState() => _RecordingsFeedScreenState();
}

class _RecordingsFeedScreenState extends State<RecordingsFeedScreen> {
  late final RecordingsFeedViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RecordingsFeedViewModel(deviceSN: widget.deviceSN);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceModel = Provider.of<DeviceModel>(context);
    final displayName = widget.deviceName ?? deviceModel.deviceName;
    final isWide = MediaQuery.of(context).size.width >= 750;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: isWide
              ? null
              : AppBar(
                  backgroundColor: AppColors.surface,
                  elevation: 0.5,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppColors.textPrimary, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text('文件管理', style: DeviceInfoText.rowLabel),
                ),
          body: Stack(
            children: [
              isWide
                  ? _buildPcBody(displayName)
                  : _buildMobileBody(displayName),
              if (_viewModel.deleteTargetId != null) _buildDeleteConfirmDialog(),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // PC 布局 (Figma 669:4001): 800 宽内容区居中
  // ============================================================
  static const double _contentWidth = 800;

  Widget _buildPcBody(String displayName) {
    return Center(
      child: SizedBox(
        width: _contentWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            // 面包屑 (左) ⟷ 储存卡 (右)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildContentHeader(displayName)),
                const SizedBox(width: 16),
                _buildStorageCard(displayName),
              ],
            ),
            const SizedBox(height: 24),
            _buildTabsRow(),
            const SizedBox(height: 16),
            Expanded(child: _buildFileTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBody(String displayName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _buildStorageCard(displayName),
          const SizedBox(height: 16),
          _buildTabsRow(),
          const SizedBox(height: 8),
          Expanded(child: _buildFileTable()),
        ],
      ),
    );
  }

  // ============================================================
  // 面包屑 (Figma 669:4058): 「Talix AI Note › 文件管理」
  // 16px, 设备名 #333333 + 16×16 箭头 + 「文件管理」#999999, gap 8。
  // 被 pushed 进入时在最前面补一个「返回」按钮。
  // ============================================================
  Widget _buildContentHeader(String deviceName) {
    const crumbStyle = TextStyle(
      fontFamily: 'Segoe UI',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.0,
      color: AppColors.textPrimary,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (Navigator.canPop(context)) ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios,
                        size: 14, color: AppColors.textPrimary),
                    SizedBox(width: 4),
                    Text('返回', style: DeviceInfoText.rowLabel),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Text(
            deviceName,
            style: crumbStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        const DeviceRowChevron(),
        const SizedBox(width: 8),
        Text(
          '文件管理',
          style: crumbStyle.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ============================================================
  // Tabs (Figma 669:4047): 选中项绿色 Bold + 下方 24×2 绿色下划线,
  // 未选中项 #333333 Regular 无下划线, 项间距 16。
  // ============================================================
  Widget _buildTabsRow() {
    return Row(
      children: [
        _buildTab(
          label: '设备储存',
          isActive: _viewModel.activeTab == 'device',
          onTap: () => _viewModel.setActiveTab('device'),
        ),
        const SizedBox(width: 16),
        _buildTab(
          label: '主机储存',
          isActive: _viewModel.activeTab == 'host',
          onTap: () => _viewModel.setActiveTab('host'),
        ),
      ],
    );
  }

  Widget _buildTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textPrimary,
                height: 1.0,
                letterSpacing: 16 * 0.004,
              ),
            ),
            const SizedBox(height: 8),
            // 24×2 绿色下划线, 未选中时占位透明以保持行高一致
            Container(
              width: 24,
              height: 2,
              color: isActive ? AppColors.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 存储用量卡 (Figma 669:4052)
  // 208 宽, padding 16, 1px rgba(0,0,0,0.1) 描边 + 4px 圆角。
  // 上行: 设备名 14px #333333 ⟷ 用量 12px #999999
  // 下行: 2px 进度条 (#D9D9D9 底 + 主色填充)
  // ============================================================
  Widget _buildStorageCard(String displayName) {
    return Container(
      width: 208,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x1A000000), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: DeviceInfoText.rowLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(_viewModel.usedText, style: DeviceInfoText.rowSubtitle),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 2,
              color: AppColors.progressTrack,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _viewModel.usagePercent,
                child: Container(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 文件表格 (Figma 669:4002)
  // ============================================================
  Widget _buildFileTable() {
    final files = _viewModel.visibleRecordings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTableHeader(),
        Expanded(
          child: files.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final item = files[index];
                    return _FileRow(
                      item: item,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TranscriptionDetailScreen(
                              initialTitle: item.title,
                              initialDate: '${item.dateText} ${item.timeText}',
                            ),
                          ),
                        );
                      },
                      onDelete: () => _viewModel.requestDelete(item.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 表头 (Figma 669:4003): padding 12/8, 12px #999999, 下边 1px #E9E9E9
  Widget _buildTableHeader() {
    const headerStyle = TextStyle(
      fontFamily: 'Segoe UI',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.tableDivider, width: 1),
        ),
      ),
      child: const Row(
        children: [
          Expanded(child: Text('文件名', style: headerStyle)),
          SizedBox(width: 24),
          SizedBox(
            width: _FileRow.dateColumnWidth,
            child: Text('日期时间', style: headerStyle),
          ),
          SizedBox(width: 24),
          SizedBox(
            width: _FileRow.sizeColumnWidth,
            child: Text('大小', style: headerStyle),
          ),
          SizedBox(width: 24),
          SizedBox(
            width: _FileRow.actionColumnWidth,
            child: Text('操作', textAlign: TextAlign.right, style: headerStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 48, color: AppColors.progressTrack),
          SizedBox(height: 12),
          Text('暂无录音文件', style: DeviceInfoText.rowSubtitle),
        ],
      ),
    );
  }

  // 删除确认弹层 (Figma 1218:5042 删除确认提示)
  Widget _buildDeleteConfirmDialog() {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _viewModel.cancelDelete,
            child: Container(color: Colors.black54),
          ),
          Center(
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '删除所选文件',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      InkWell(
                        onTap: _viewModel.cancelDelete,
                        child: const Icon(Icons.close, size: 16, color: Color(0xFF000000)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '所选文件将被永久删除无法恢复,您确定要删除吗?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF262626),
                      height: 1.43,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildDialogButton(
                        label: '取消',
                        filled: false,
                        onTap: _viewModel.cancelDelete,
                      ),
                      const SizedBox(width: 12),
                      _buildDialogButton(
                        label: '删除',
                        filled: true,
                        onTap: () => _viewModel.confirmDelete(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF18181B) : Colors.white,
          border: Border.all(
            color: filled ? const Color(0xFF18181B) : const Color(0xFFD1D5DB),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: filled ? Colors.white : const Color(0xFF18181B),
            height: 1.43,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 单行文件 (Figma 669:4008)
// padding 16/8, 列间距 24, 下边 1px #E9E9E9
// 文件名 14px #333333 (fill) / 日期时间 14px #999999 (160)
// 大小 14px #999999 (56) / 操作 24×24 删除图标 (64, 右对齐)
// ============================================================
class _FileRow extends StatelessWidget {
  final dynamic item; // RecordingItem (avoid extra import in this section)
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FileRow({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  static const double dateColumnWidth = 160;
  static const double sizeColumnWidth = 56;
  static const double actionColumnWidth = 64;

  static const TextStyle _nameStyle = TextStyle(
    fontFamily: 'Segoe UI',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  static const TextStyle _metaStyle = TextStyle(
    fontFamily: 'Segoe UI',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.0,
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.tableDivider, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title as String,
                style: _nameStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: dateColumnWidth,
              child: Text(
                '${item.dateText} ${item.timeText}',
                style: _metaStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: sizeColumnWidth,
              child: Text(item.fileSize as String, style: _metaStyle),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: actionColumnWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(4),
                  child: Tooltip(
                    message: '移至回收站',
                    child: SvgPicture.asset(
                      'assets/images/ic_move_to_trash.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
