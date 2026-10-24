#!/usr/bin/env python3
"""写出磁盘映像根目录的 .DS_Store：应用在左，“应用程序”在右。

依赖：python3 -m pip install ds-store
用法：python3 packaging/macos/write_dmg_layout.py packaging/macos/dmg-layout.dsstore
"""

import sys

from ds_store import DSStore

APP_NAME = "bili_audio.app"
# 图标坐标是窗口内容区里的位置。x 越大越靠右。
APP_POSITION = (170, 180)
APPLICATIONS_POSITION = (470, 180)


def main() -> None:
    output = sys.argv[1] if len(sys.argv) > 1 else "dmg-layout.dsstore"
    window = {
        "ShowStatusBar": False,
        "WindowBounds": "{{200, 120}, {680, 380}}",
        "ContainerShowSidebar": False,
        "PreviewPaneVisibility": False,
        "SidebarWidth": 0,
        "ShowTabView": False,
        "ShowToolbar": False,
        "ShowPathbar": False,
        "ShowSidebar": False,
    }
    icons = {
        "viewOptionsVersion": 1,
        "backgroundType": 0,
        "backgroundColorRed": 1.0,
        "backgroundColorGreen": 1.0,
        "backgroundColorBlue": 1.0,
        "gridOffsetX": 0.0,
        "gridOffsetY": 0.0,
        "gridSpacing": 100.0,
        "arrangeBy": "none",
        "showIconPreview": True,
        "showItemInfo": False,
        "labelOnBottom": True,
        "textSize": 13.0,
        "iconSize": 96.0,
        "scrollPositionX": 0.0,
        "scrollPositionY": 0.0,
    }
    with DSStore.open(output, "w+") as store:
        store["."]["vSrn"] = ("long", 1)
        store["."]["bwsp"] = window
        store["."]["icvp"] = icons
        store["."]["icvl"] = ("type", b"icnv")
        store[APP_NAME]["Iloc"] = APP_POSITION
        store["Applications"]["Iloc"] = APPLICATIONS_POSITION


if __name__ == "__main__":
    main()
