import 'package:flutter/material.dart';

import '../../core/utils/cover_url.dart';

/// 封面图; 缺失或加载失败时显示音符占位
class CoverImage extends StatelessWidget {
  const CoverImage(
    this.url, {
    super.key,
    this.fallbackUrl,
    this.size = 48,
    this.radius = 6,
  });

  final String? url;

  /// 主图加载失败时改用这张，例如官方专辑图失败后回到 B 站封面。
  final String? fallbackUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note,
        color: scheme.onSurfaceVariant,
        size: size * 0.5,
      ),
    );
    final u = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: u == null || u.isEmpty
            ? placeholder
            : Image.network(
                // B 站封面支持缩略图参数, 减少流量
                absoluteCoverUrl(u) ?? u,
                fit: BoxFit.cover,
                semanticLabel: '',
                errorBuilder: (_, _, _) {
                  final fallback = fallbackUrl;
                  if (fallback != null &&
                      fallback.isNotEmpty &&
                      fallback != u) {
                    return CoverImage(fallback, size: size, radius: radius);
                  }
                  return placeholder;
                },
              ),
      ),
    );
  }
}
