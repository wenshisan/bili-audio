import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ============================================================
// AuthAssets – 内联 SVG 资源（避免打包加载问题）
// Figma 节点: 669:4634  Talix 品牌 Logo 160x34 (#78FA7C)
//             669:4645  eye-off 24x24
//             669:5098  eye-on  24x24
// ============================================================
class AuthAssets {
  // ── Talix 品牌 Logo 160x34，绿色 #78FA7C ─────────────────
  // 直接嵌入 Figma 导出的 path 数据，fill 改为 currentColor 以便灵活着色
  static const String talixLogo = '''
<svg width="160" height="34" viewBox="0 0 160 34" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M43.8139 28.3085H56.5805L57.8827 33.9943H70.4503L60.7063 0H47.1273L28.6128 33.9943H40.9644L43.8139 28.3085ZM52.6764 7.76882H52.8465C53.149 12.3341 53.8836 17.1465 55.0448 22.2031H46.7931C49.1556 17.2816 51.1148 12.4691 52.6764 7.76882ZM1.85835 0.709565C1.46939 1.08024 1.23314 1.51707 1.14671 2.02263H1.11214L0 7.76882H11.1098L7.62067 34H19.8771L23.346 7.76882H32.4938L33.7558 0.00572934H3.37385C2.80338 0.060425 2.29917 0.293065 1.86124 0.709565M147.792 0.00572934C147.159 0.0201424 146.608 0.252782 146.144 0.709565C146.058 0.781445 145.989 0.853324 145.934 0.925204L145.92 0.910791L141.65 6.57641C140.497 8.07056 139.875 8.93239 139.792 9.16226H139.636C139.408 8.38932 137.936 5.33819 135.21 0.00572934H126.244C125.596 0.0201424 125.037 0.252782 124.562 0.709565C124.072 1.18372 123.818 1.75839 123.795 2.43636C123.778 2.88168 123.867 3.29245 124.066 3.66036L131.816 16.3363L116.35 34H129.558L135.401 26.8949C136.291 25.8261 137.034 24.7516 137.628 23.6742H137.783C137.901 24.1481 139.552 27.3547 142.739 33.2904C142.866 33.5201 142.992 33.7587 143.119 34H156.537L145.476 16.2271L160 0.00572934H147.79M78.8174 2.16344L78.8028 2.14902L74.5877 33.997H96.2427L97.2941 26.1277H87.7316L91.1919 0.00572934H81.2087C80.5748 0.0286424 80.0303 0.264238 79.5722 0.709565C79.1458 1.12052 78.8951 1.60613 78.8201 2.16344M105.606 0.709565C105.194 1.11184 104.95 1.57158 104.875 2.09155H104.84L100.59 34H112.706L117.203 0.00572934H107.275C106.626 0.0201424 106.07 0.252782 105.606 0.709565Z" fill="#78FA7C"/>
</svg>
''';

  // ── eye-on 24x24 ──────────────────────────────────────────
  static const String eye = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M2.5 12C2.5 12 6 4.5 12 4.5C18 4.5 21.5 12 21.5 12C21.5 12 18 19.5 12 19.5C6 19.5 2.5 12 2.5 12Z" stroke="#999999" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="12" cy="12" r="3" stroke="#999999" stroke-width="1.5"/>
</svg>
''';

  // ── eye-off 24x24 ─────────────────────────────────────────
  static const String eyeOff = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 3L21 21" stroke="#999999" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M10.59 10.59A2 2 0 0013.41 13.41" stroke="#999999" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M16.68 16.68C15.26 17.84 13.69 18.5 12 18.5C6 18.5 2.5 12 2.5 12C3.62 10.13 5.21 8.39 7.13 7.16" stroke="#999999" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M9.9 5.08C10.59 4.96 11.29 4.9 12 4.9C18 4.9 21.5 11.9 21.5 11.9C20.69 13.27 19.66 14.55 18.45 15.66" stroke="#999999" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M14.12 14.12A3 3 0 019.88 9.88" stroke="#999999" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';
}

/// Talix 品牌 Logo 160×34，绿色 #78FA7C
class AuthTalixLogo extends StatelessWidget {
  const AuthTalixLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      AuthAssets.talixLogo,
      width: 160,
      height: 34,
      fit: BoxFit.contain,
    );
  }
}
