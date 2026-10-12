"""从 Figma 导出的 assets/app_icon.png 生成各平台图标。

用法:  python tool/gen_app_icons.py

产出:
  assets/app_icon.png            —— 托盘/通用 PNG (256x256)
  assets/app_icon.ico            —— 托盘 ICO (多分辨率)
  windows/runner/resources/app_icon.ico —— Windows exe 图标 (多分辨率)

源图: Figma 669:4543「应用图标 1」480x480 圆角方形 (绿底 #78FA7C + 白色 TALIX Connect)
"""

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "app_icon.png"

# Windows ICO 常规尺寸集; 16/20/24/32 供托盘与任务栏, 更大尺寸供资源管理器与设置页
ICO_SIZES = [(16, 16), (20, 20), (24, 24), (32, 32), (40, 40), (48, 48), (64, 64), (128, 128), (256, 256)]


def main() -> int:
    if not SRC.exists():
        print(f"源图不存在: {SRC}", file=sys.stderr)
        return 1

    src = Image.open(SRC).convert("RGBA")
    print(f"源图: {SRC.name} {src.size[0]}x{src.size[1]}")

    targets = [
        ROOT / "assets" / "app_icon.ico",
        ROOT / "windows" / "runner" / "resources" / "app_icon.ico",
    ]
    for out in targets:
        out.parent.mkdir(parents=True, exist_ok=True)
        src.save(out, format="ICO", sizes=ICO_SIZES)
        print(f"写入 ICO: {out.relative_to(ROOT)}  ({len(ICO_SIZES)} 个尺寸)")

    # 托盘 PNG (macOS/Linux 用) 缩到 256, 避免 480 原图过大
    png_out = ROOT / "assets" / "app_icon.png"
    src.resize((256, 256), Image.LANCZOS).save(png_out, format="PNG", optimize=True)
    print(f"写入 PNG: {png_out.relative_to(ROOT)}  (256x256)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
