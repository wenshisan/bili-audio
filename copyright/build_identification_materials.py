# -*- coding: utf-8 -*-
"""排列音赴光年 V0.1.0 的软件著作权一般交存材料。

程序鉴别材料：手写 Dart 源程序前 30 页、后 30 页，每页 50 行。
文档鉴别材料：设计说明书。不足 60 页时提交全文，超过 60 页时提交前 30 页和后 30 页，每页 32 行。
"""

from __future__ import annotations

import html
import os
import re
import shutil
import subprocess
import tempfile
import unicodedata
from pathlib import Path

ROOT = Path(r"d:\Code\yinfu\flutter-app-deep\bili_audio")
LIB = ROOT / "lib"
OUT = Path(r"d:\Code\yinfu\flutter-app-deep\copyright")

NAME = "音赴光年"
VERSION = "V0.1.0"
HEADER = f"{NAME} {VERSION}"

CODE_LINES = 50
DOC_LINES = 32
CODE_WIDTH = 92
DOC_WIDTH = 78

RANK = {
    "main.dart": 0,
    "app": 1,
    "core": 2,
    "domain": 3,
    "data": 4,
    "features": 5,
    "l10n": 6,
}

GROUP_TITLE = {
    "main.dart": "程序入口",
    "app": "应用外壳",
    "core": "基础能力",
    "domain": "领域规则",
    "data": "数据与播放实现",
    "features": "界面交互",
    "l10n": "界面文案",
}

GROUP_ROLE = {
    "main.dart": "负责进程启动、错误兜底、桌面单实例，以及把界面交到应用外壳。",
    "app": "负责主题、路由、窗口、托盘和按窗口尺寸切换布局。",
    "core": "负责日志、路径、安全存储和与具体页面无关的工具。",
    "domain": "负责播放顺序、标题整理、歌词评分等不依赖界面的规则。",
    "data": "负责搜索、音频地址、数据库、缓存、歌词来源和系统媒体会话。",
    "features": "负责搜索、播放、歌单、队列、歌词和设置这些用户能看到的页面。",
    "l10n": "负责界面上使用的中文文案。",
}


NARRATIVE = r"""
1 文档说明
本文件是音赴光年 V0.1.0 的设计说明书，用作该软件著作权登记的文档鉴别材料。说明书说明这套程序做什么、分成哪些部分、数据放在哪里、播放和歌词如何衔接。文中的模块名称、数据表和界面分档与同期源程序一致。源程序用 Dart 编写，界面用 Flutter 组织，同一套代码运行在 Windows、macOS、Linux、Android 和 iOS 上。

2 软件概述
音赴光年是一款音频播放软件，英文名 Soundward Lightyear。它播放音乐视频里的声音，不播放画面。用户可以按歌名或歌手搜索，从结果里点选曲目后开始听。界面上的标题整理成歌名和歌手。歌词单独显示，并跟着当前进度往下走。一首曲目听过之后把音频留在本机，再次播放时直接读本地文件。没有网络时，软件不再拉取新的内容，只从已经留下的曲目里继续播放。

歌单保存在当前这台设备上。用户可以新建歌单、改名、删除、调整曲目顺序，也可以把当前队列整列存成一张歌单。搜索、播放、看歌词和编辑歌单不要求登录。登录之后才能使用更高的音质档。登录凭据只放在本机的系统安全存储里。

3 开发目的与运行环境
开发目的是在电脑和手机上收听音频，并完成搜索、歌词、本地歌单和离线续播。面向领域是音乐。开发使用的操作系统是 Windows 11，开发工具是 Flutter。运行平台包括 Windows、Android、macOS、iOS 和 Linux。运行时依赖 Flutter 运行环境。编程语言是 Dart。

开发所用的硬件是普通个人计算机，处理器 2GHz 及以上，内存 8GB 及以上。运行时的硬件是个人计算机或手机，内存 4GB 及以上。软件不在界面中解码视频画面，后台播放只处理音频。

4 总体结构
源程序放在 lib 目录，按职责分成五层。main.dart 是进程入口。app 目录放置应用外壳，包括主题、路由、桌面窗口和按窗口尺寸决定的布局。core 目录放置日志、文件路径和安全存储。domain 目录放置播放队列、标题清洗和歌词评分，这些规则不依赖具体页面。data 目录放置网络访问、SQLite 数据库、音频缓存和系统媒体会话。features 目录放置搜索、播放、歌单、队列、歌词和设置页面。

页面通过仓储接口读取搜索结果和音频地址，不直接拼接网络请求。播放顺序由 PlaybackQueue 决定，不把随机顺序交给播放器组件内部生成。这样，切到随机、再切回顺序时，可以回到原来的排列，并停在当前这首上。

5 启动流程
进程从 main 进入。启动时先接住界面构建错误和未捕获异常，写入日志，避免页面构建失败时没有任何记录。桌面端接着初始化无边框窗口。若本机已经有一个实例在运行，新的实例不另开一份界面，而是通知已有实例把主窗口显示出来并放到前台。通道名称是 bili_audio/single_instance，调用的方法是 showMainWindow。

窗口就绪后完成依赖装配：准备数据库、缓存目录、播放器和歌词管理器，再把界面交给 BiliAudioApp。用户上次留下的队列、播放模式和进度会在打开后恢复，但不会自动开始出声，需要用户再次按下播放。若启动过程本身失败，入口显示单独的错误页，而不是空白窗口。

6 窗口与布局
布局只看窗口的逻辑像素宽高，不按手机、平板或电脑的设备类型写死。宽度小于 600 为 compact。600 至 840 为 medium。840 至 1194 为 expanded。1194 至 1600 为 large。1600 以上为 extraLarge。高度小于 500 为 short。500 至 844 为 regular。844 以上为 tall。

高度不足 500，或者宽度不足 600 时，使用底部导航。底部有三个入口：发现、歌单、我的。正在播放的内容收成底部一条迷你播放条。宽度达到 600 并且高度至少 500 时，导航改到左侧。宽度达到 1194 并且高度至少 500 时，使用左右分栏：左侧是当前页面，右侧常驻正在播放，包括封面、当前一句歌词、进度、控制条和队列。左右之间的分隔条可以拖动。左栏占可用宽度的比例限制在 0.4 到 0.75，松手后记住这个比例。11 英寸平板横屏宽度是 1194，因此落在这套左右分栏里。窗口拉宽或收窄时，按上述档位当场切换，不需要重启。

另有一套车机布局，和上面的三档无关。设置为自动时，只在系统报告车载界面时使用大按钮。也可以始终打开或始终关闭。车机界面左侧是封面和播放控制，右侧在队列和歌词之间切换。

桌面窗口无边框，标题栏上提供最小化、最大化和关闭。关闭窗口时收到系统托盘，不退出进程。托盘菜单可以再次打开窗口。主题可以跟随系统、固定浅色或固定深色，并可以更换一套主题色。

7 发现与搜索
发现页在用户还没有输入关键词时展示音乐推荐。推荐分成两组。一组是排行，包括按近期热度、评价相对更高的曲目，以及原创、翻唱、音乐视频、现场、演奏和 VOCALOID。另一组是年代，曲目来自年代歌单，播放地址再按歌名和歌手查找。推荐可以先把已经拿到的一部分显示出来，不必等整页全部到齐。

搜索按歌名或歌手进行，结果分页加载，并记住搜索历史。时长超过 15 分钟的结果会被标出并淡化，便于留下能当歌曲听的内容。结果进入界面之前先做标题整理，列表上显示整理后的歌名和歌手。点选一首之后，若该视频有多个分 P，每一 P 作为一首独立曲目进入队列，按顺序衔接，并各自匹配歌词。界面上能看到当前是第几 P、这一 P 的标题，以及它属于哪一个视频。

8 标题整理
视频标题里常夹着音质、官方音乐视频、4K、翻唱、中字这类修饰。TitleCleaner 去掉这类括号修饰，再按分隔符拆出歌名和歌手，界面统一显示为歌名和歌手。原始标题仍然保留，用户可以查看。整理错了可以手改，改过的歌名和歌手会写进曲目记录，下次仍用改过的结果。

标题里带有伴奏、纯音乐或 Instrumental 时，把这首标成无歌词，不再去查找歌词。整理后的歌名和歌手同时用于歌词匹配，减少标题噪声造成的错配。列表、播放页、通知和锁屏使用同一套整理结果。

9 播放队列
播放顺序由 PlaybackQueue 统一管理。模式有五种：顺序播放、列表循环、单曲循环、随机播放和智能随机。顺序播放按队列走到最后一首后停止。列表循环走到最后一首后回到第一首。单曲循环重复当前这首。

随机播放不在进入模式时就把整列打乱。当前这首保持不动。用户点下一首时，才从这一轮还没有听过的曲目里抽一首。一轮之内不重复。这一轮都听过之后重新开始，刚离开的那首不会马上再被抽到。智能随机在此之上尽量换一位歌手：队列里还有其他歌手时，下一首尽量不是同一位。

上一首按实际听过的顺序往回退，退到的是刚才那首，不是列表里的相邻项。从随机切回顺序时，队列恢复成原来的排列，并停在当前这首上。随机模式下不能拖拽改顺序。用户也可以指定下一首，被指定的曲目优先于随机抽取。

播放控制包括开始、暂停、拖动进度、上一首和下一首。倍速可以选 0.75、1、1.25、1.5 和 2。定时停止可以选 15 分钟、30 分钟、60 分钟，也可以在当前这首结束或下一首结束后停下。当前队列可以移除曲目，清空时可以保留正在听的一首，也可以把整列存成歌单。播放失败时跳过当前这首，避免停在无法出声的一项上。

10 音频地址与本地缓存
播放前按曲目和音质档解析音频地址。音质档包括 64K、132K、192K、Dolby 和 Hi-Res。未登录时最高使用 132K。音频地址有时效，过期后在后台重新解析，不要求用户重新点播放。

播放过程中把音频写入本机。同一首再次播放并且本地文件已经完整时，直接读本地文件，不再请求音频地址。封面、歌词和整理后的歌名、歌手一起留下，离线时仍能看出是哪一首。缓存上限可以在 250MB、500MB、1GB、2GB 和 5GB 里选择。空间不够时，清掉最久没有播放、并且没有放进歌单的曲目。已经放进歌单的曲目标记为保留，不参与这次清理。设置里可以查看已缓存的数量和占用，按首删除，或一次性清掉未加入歌单的缓存。未缓存的曲目仍然需要网络。

11 歌词
歌词按曲目的视频标识和分 P 标识保存，偏移也按这一对标识记住。查找时先读本机已经匹配过的结果。若用户曾经把这首标成无歌词，直接返回无歌词，不再访问外部来源。本机没有记录时，再按各来源的优先级依次查询。

匹配同时看歌名、歌手和时长。得分达到 0.80 时直接采用并写入本机。得分在 0.60 到 0.80 之间时列出候选，由用户挑选。低于 0.60 时不自动套用。同一首的并发查找会合并，避免重复请求。

歌词视图跟着播放进度滚动，点某一行会跳到对应时间。时间偏了可以按 0.1 秒微调。窄窗口里歌词在播放页中滚动。窗口更宽时，封面和歌词可以左右并排。底部迷你条只显示当前一句。桌面分栏的右侧正在播放也显示当前一句。

12 歌单与播放历史
歌单写在本机数据库里，不登录也能用。每张歌单记录名称、封面和曲目顺序。同一视频的同一分 P 在同一张歌单里只保留一次。搜索结果、正在播放的这首和当前队列都可以加入歌单，也可以在选择歌单时当场新建一张。

打开一张歌单后可以按歌单顺序从第一首播放，也可以按随机规则打散后播放。点列表中的某一首，从那一首开始播放整张歌单。曲目可以拖动调整顺序，也可以移除。放进歌单的曲目受到缓存保护。

播放历史和歌单在同一个入口里，用顶部标签分开。历史按今天、昨天、本周和更早分组，可以清空。每条历史记录保存播放时间和播放到的位置。

13 登录
不登录就可以搜索、以基础音质播放、看歌词、使用缓存和编辑本地歌单。需要更高音质，或内容本身要求登录时，再提示登录。登录方式包括扫码和网页。确认登录后得到的凭据交给本机系统安全存储，不写入普通文本设置，也不复制到其他设备。

14 本机数据
业务数据放在 SQLite 数据库中，主要有以下各表。

曲目表 tracks 以视频标识 bvid 和分 P 标识 cid 为主键。其中保存原始标题、整理后的歌名、歌手、用户是否手改过、时长、封面、上传者、分 P 序号和总分 P 数。时长必须大于 0。

歌单表 playlists 保存名称、封面、是否只读、来源和来源标识。名称长度限制在 1 到 100。歌单与曲目的关联表 playlist_tracks 保存所属歌单、曲目标识和从 0 开始的顺序。删除歌单时，关联行一并删除。

播放历史表 play_history 保存曲目、播放时间、播放到的毫秒位置、完成度和来源。完成度限制在 0 到 1。

歌词缓存表 lyrics_cache 以 bvid 和 cid 为主键，保存本地歌词文件相对路径、来源、匹配得分、用户校准的偏移毫秒，以及是否标成无歌词。

音频缓存索引表 cache_index 以缓存键为主键。缓存键由视频标识、分 P 标识和音质档组成。表中保存相对路径、文件大小、是否完整、已下载字节、最近播放时间，以及是否因在歌单中而保留。已下载字节不能大于文件大小。

音频地址表 stream_urls 按曲目和音质档保存地址、备用地址、媒体类型和过期时间。队列快照表 queue_snapshot 只保留一行，保存队列原文、当前顺序、光标、播放模式、随机种子、已播放记录和进度。设置表 settings 以键值保存音质、主题和缓存上限等偏好。

15 桌面媒体控制与更新
桌面端把当前曲目交给系统媒体会话，系统媒体键可以暂停和切歌。通知和锁屏显示整理后的歌名和歌手。应用重新打开后恢复上次的队列和进度，但不自动播放。

设置里可以检查更新。安装包的构建号高于本机时提示升级。更新说明和安装包来自发布记录。预发布构建不单独当成一个需要提示的正式版本。安装前检查安装包是否对得上当前系统。

16 出错与离线
页面构建失败和未捕获异常写入日志。日志对凭据类字段做脱敏，不把敏感值原样落下。音频地址失效或网络失败时，播放器跳过无法播放的一项并继续队列。仅在本地已有文件时，没有网络也可以播放已缓存的曲目。未缓存的曲目仍要联网。队列、歌单、歌词偏移和主题都写在本机，不依赖这次是否登录。

17 使用说明之搜索与播放
打开软件后进入发现页。尚未输入关键词时，页面展示音乐推荐。推荐里可以切换热度、评价、原创、翻唱、音乐视频、现场、演奏、VOCALOID，也可以按年代查看。点一首即从该首开始播放。若这是一个多分 P 的合集，各分 P 按顺序进入队列，每一 P 单独显示标题并单独匹配歌词。

需要指定曲目时，在搜索框输入歌名或歌手。结果按页继续加载。时长超过 15 分钟的条目会被标出并淡化。点开一条结果后开始播放，界面标题使用整理后的歌名和歌手。搜索过的词留在本机，下次可以再次点选。

播放页可以暂停、继续、拖动进度、切到上一首或下一首。倍速在 0.75、1、1.25、1.5、2 之间选择。定时停止可以选择 15 分钟、30 分钟、60 分钟，也可以选择播完当前这首或播完下一首后停止。当前队列里可以移除曲目，清空时可以留下正在听的一首，也可以把整列保存为歌单。

播放模式从顺序、列表循环、单曲循环、随机和智能随机里选择。随机时当前这首不动，从下一首开始在本轮还没听过的曲目里抽取。上一首回到刚才实际听过的那首。随机时不能拖动改变队列顺序。从随机改回顺序后，队列回到原来的先后，并停在当前这首。

18 使用说明之歌词、歌单与缓存
播放时软件自动查找歌词。已经匹配过的直接使用。没有记录时再按各来源查找。很像的歌词直接采用。不太确定时列出候选，由用户选择。对不上则不自动填上。点歌词的某一行，播放跳到对应时间。若歌词整体偏早或偏晚，按 0.1 秒调整，这个偏移会按该视频的该分 P 记住。也可以把这首标成无歌词，以后不再查找。标题里已经能看出是伴奏或纯音乐的，不会去查找歌词。

歌单从底部或侧栏的歌单入口进入。可以新建、改名和删除。把搜索结果、正在播放的曲目或当前队列放进歌单时，同一个视频的同一个分 P 不会重复加入。打开一张歌单后，可以按列表顺序全部播放，也可以整张随机播放。点其中一首，则从这一首开始播放这张歌单。曲目可以拖动排序，也可以从歌单中移除。

听过的曲目会写入播放历史。历史和歌单在同一入口，用顶部标签切换，并按今天、昨天、本周和更早分组。历史可以清空。

音频在播放时写入本机。同一首再次播放时，若本地文件已经完整，就不再请求音频地址。设置中可以查看缓存占用，按首删除，或清掉还没有放进歌单的缓存。缓存上限在 250MB、500MB、1GB、2GB、5GB 中选择。已经放进歌单的曲目会留下来。没网时可以继续听已经缓存的曲目。

19 使用说明之账号、外观与更新
不登录即可搜索、播放、看歌词、缓存和编辑歌单。未登录时音质最高到 132K。需要更高音质时再登录。登录可以用扫码或网页完成。登录凭据只放在本机系统安全存储中。

外观可以跟随系统，也可以固定为浅色或深色，并可以更换主题色。车机布局可以设为自动、始终开启或关闭。自动时只在系统处于车载界面时使用大按钮。车机界面一边是封面和播放控制，另一边在队列和歌词之间切换。

桌面端把窗口关闭后，程序留在系统托盘里，媒体键仍可以暂停和切歌。再次打开时恢复上次的队列、模式和进度，但不会自动出声。设置里可以检查更新。比本机更新的正式版本会提示安装。

把窗口拉窄或拉宽时，导航和播放区域按宽度和高度切换。宽度不足 600，或高度不足 500 时，使用底部三个入口和底部播放条。更宽并且足够高时，导航移到左侧。宽度达到 1194 且高度至少 500 时，右侧一直留着正在播放，中间的分隔可以拖动，左侧大约占四成到七成五。

20 源程序与说明书的对应关系
本说明书后面按源程序文件列出各文件的位置、文件自身的说明、定义的类型，以及可从外部调用的操作。文件顺序与程序鉴别材料里的源程序顺序相同：先是入口，然后是应用外壳、基础能力、领域规则、数据与播放实现，最后是界面。程序鉴别材料取的是这条源程序的前 30 页和后 30 页。页眉上的软件名称和版本号与本说明书相同。
"""


def display_width(text: str) -> int:
    width = 0
    for ch in text:
        width += 2 if unicodedata.east_asian_width(ch) in {"W", "F"} else 1
    return width


def _word_char(ch: str) -> bool:
    return ch.isascii() and (ch.isalnum() or ch in "._+-")


def wrap_units(text: str, limit: int) -> list[str]:
    if text == "":
        return [""]
    tokens: list[str] = []
    buf = ""
    for ch in text:
        if buf and _word_char(ch) and _word_char(buf[-1]):
            buf += ch
        else:
            if buf:
                tokens.append(buf)
            buf = ch
    if buf:
        tokens.append(buf)

    lines: list[str] = []
    current = ""
    width = 0
    for token in tokens:
        token_width = display_width(token)
        sticky = token in "。，、；：！？）》」』】"
        if current and width + token_width > limit and not sticky:
            lines.append(current)
            current = token.lstrip() if token == " " else token
            width = display_width(current)
            continue
        if not current and token == " ":
            continue
        current += token
        width += token_width
    if current:
        lines.append(current)
    return [line for line in lines if line != ""] or [""]


def narrative_lines() -> list[str]:
    lines: list[str] = []
    for block in NARRATIVE.strip().split("\n\n"):
        raw = [part.strip() for part in block.splitlines() if part.strip()]
        if not raw:
            continue
        if re.match(r"^\d+ ", raw[0]) and len(raw[0]) <= 24:
            lines.extend(wrap_units(raw[0], DOC_WIDTH))
            body = "".join(raw[1:])
            if body:
                lines.extend(wrap_units("　　" + body, DOC_WIDTH))
        else:
            lines.extend(wrap_units("　　" + "".join(raw), DOC_WIDTH))
    return [line for line in lines if line.strip()]


def collect_sources() -> list[Path]:
    files: list[Path] = []
    for path in LIB.rglob("*.dart"):
        rel = path.relative_to(LIB).as_posix()
        name = path.name
        if name.endswith(".g.dart") or name.endswith(".freezed.dart"):
            continue
        if rel.startswith("l10n/gen/"):
            continue
        files.append(path)

    def sort_key(path: Path) -> tuple[int, str]:
        rel = path.relative_to(LIB).as_posix()
        top = "main.dart" if rel == "main.dart" else rel.split("/", 1)[0]
        return (RANK.get(top, 9), rel)

    return sorted(files, key=sort_key)


def normalize_source(text: str) -> list[str]:
    text = text.replace("\t", "  ").replace("\r\n", "\n").replace("\r", "\n")
    raw = [line.rstrip() for line in text.split("\n")]
    collapsed: list[str] = []
    blank = 0
    for line in raw:
        if line.strip() == "":
            blank += 1
            if blank <= 1:
                collapsed.append("")
        else:
            blank = 0
            collapsed.append(line)
    while collapsed and collapsed[0] == "":
        collapsed.pop(0)
    while collapsed and collapsed[-1] == "":
        collapsed.pop()
    return collapsed


def source_lines(files: list[Path]) -> tuple[list[str], int]:
    lines: list[str] = []
    physical = 0
    for path in files:
        rel = path.relative_to(ROOT).as_posix()
        body = normalize_source(path.read_text(encoding="utf-8"))
        physical += len(body)
        if lines:
            lines.append("")
        lines.append(f"// ===== {rel} =====")
        for line in body:
            lines.extend(wrap_units(line, CODE_WIDTH))
    return lines, physical


CLASS_RE = re.compile(
    r"^(?:abstract\s+|sealed\s+|base\s+|final\s+|interface\s+)*"
    r"(class|enum|mixin|extension)\s+(\w+)"
)
def file_brief(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    doc: list[str] = []
    started = False
    for line in text.splitlines()[:100]:
        stripped = line.strip()
        if stripped.startswith("///"):
            started = True
            doc.append(stripped[3:].strip())
            continue
        if started:
            break
    comment = re.sub(r"\[(.+?)\]", r"\1", "".join(doc))
    comment = re.sub(r"\s+", "", comment)
    if len(comment) > 180:
        comment = comment[:180] + "。"

    source_lines_raw = text.splitlines()
    types: list[str] = []
    notes: list[str] = []
    for index, line in enumerate(source_lines_raw):
        class_match = CLASS_RE.match(line)
        if not class_match:
            continue
        name = class_match.group(2)
        if name.startswith("_"):
            continue
        types.append(name)
        docs: list[str] = []
        cursor = index - 1
        while cursor >= 0 and source_lines_raw[cursor].strip().startswith("///"):
            docs.append(source_lines_raw[cursor].strip()[3:].strip())
            cursor -= 1
        docs.reverse()
        class_comment = re.sub(r"\[(.+?)\]", r"\1", "".join(docs))
        class_comment = re.sub(r"\s+", "", class_comment)
        if class_comment and class_comment != comment:
            if not class_comment.endswith("。"):
                class_comment += "。"
            notes.append(f"{name}：{class_comment}")

    rel = path.relative_to(ROOT).as_posix()
    top = "main.dart" if rel == "lib/main.dart" else rel.split("/")[1]
    parts = [f"文件 {rel}。"]
    if comment:
        parts.append(comment if comment.endswith("。") else comment + "。")
    else:
        parts.append(GROUP_ROLE.get(top, "该文件实现音赴光年中的一项具体功能。"))
    if types:
        shown = "、".join(types[:8])
        parts.append(f"本文件定义了{shown}。")
    if notes:
        parts.append("".join(notes[:4]))
    return "".join(parts)


def document_lines(files: list[Path]) -> list[str]:
    lines = narrative_lines()
    current_group = ""
    chapter = 18
    for path in files:
        rel = path.relative_to(LIB).as_posix()
        top = "main.dart" if rel == "main.dart" else rel.split("/", 1)[0]
        if top != current_group:
            current_group = top
            title = GROUP_TITLE.get(top, top)
            lines.extend(wrap_units(f"{chapter} {title}", DOC_WIDTH))
            lines.extend(
                wrap_units("　　" + GROUP_ROLE.get(top, ""), DOC_WIDTH)
            )
            chapter += 1
        brief = file_brief(path)
        lines.extend(wrap_units("　　" + brief, DOC_WIDTH))
    closing = (
        "本设计说明书说明音赴光年 V0.1.0 的结构、数据、播放、歌词、缓存和歌单。"
        "界面分档、五种播放模式、音质档和本机各张数据表都以源程序为准。"
        "程序鉴别材料摘录的是同一套源程序的开头连续 30 页和结尾连续 30 页。"
        "软件名称为音赴光年，版本号为 V0.1.0。"
    )
    lines.extend(wrap_units("　　" + closing, DOC_WIDTH))
    lines = [line for line in lines if line.strip()]
    fillers = [
        "音赴光年只播放音频，不播放画面。",
        "歌单、歌词偏移、播放队列和登录凭据都保存在本机。",
        "随机播放在点下一首时才从本轮未听曲目中选取。",
        "已加入歌单的缓存曲目不参与空间不足时的清理。",
        "未登录时音质最高到 132K，音质档另有 64K、192K、Dolby 和 Hi-Res。",
        "窗口宽度达到 1194 且高度至少 500 时，右侧常驻正在播放。",
        "关闭桌面窗口后程序留在系统托盘中，再次打开不自动出声。",
        "源程序语言为 Dart，界面用 Flutter 组织。",
        "曲目表以 bvid 和 cid 为主键，保存原始标题和整理后的歌名、歌手。",
        "歌词是否采用，先看本机记录，再用 0.80 和 0.60 两档得分决定。",
        "缓存上限可在 250MB、500MB、1GB、2GB、5GB 中选择。",
        "左右分栏时，左栏宽度比例限制在 0.4 到 0.75。",
        "定时停止支持 15 分钟、30 分钟、60 分钟，以及播完当前或下一首。",
        "倍速可以选 0.75、1、1.25、1.5 和 2。",
        "同一视频的同一分 P 在同一张歌单里只保留一次。",
        "第二个桌面实例不新开窗口，只让已有窗口显示到前台。",
        "播放历史按今天、昨天、本周和更早分组。",
        "高度不足 500 时使用底部导航，避免侧栏在矮窗口里放不下。",
        "智能随机在还有其他歌手时，下一首尽量避开刚刚这位歌手。",
        "音频地址过期后在后台重新解析，不要求用户再点一次播放。",
        "标题含伴奏、纯音乐或 Instrumental 时不再查找歌词。",
        "用户手改过的歌名和歌手会保留，不在下次被整理结果覆盖。",
        "队列快照在数据库里只保留一行，用于恢复上次听到的位置。",
        "发现页可以先显示已经拿到的推荐，不必等整页到齐。",
        "搜索结果里超过 15 分钟的条目会被标出并淡化。",
        "车机大按钮可以自动跟随车载界面，也可以始终打开或关闭。",
        "正式版本的构建号高于本机时，设置里会提示更新。",
        "日志不原样记录凭据类字段。",
        "离线时只继续播放本机已经缓存完整的曲目。",
        "本说明书与程序鉴别材料使用同一软件名称和版本号。",
    ]
    pool: list[str] = []
    for sentence in fillers:
        pool.extend(wrap_units("　　" + sentence, DOC_WIDTH))
    need = (DOC_LINES - (len(lines) % DOC_LINES)) % DOC_LINES
    if need:
        if len(pool) < need:
            raise SystemExit(f"尾页还差 {need} 行，备用说明只有 {len(pool)} 行")
        lines.extend(pool[:need])
    return lines


def paginate(lines: list[str], per_page: int) -> list[list[str]]:
    return [lines[i : i + per_page] for i in range(0, len(lines), per_page)]


def select_pages(pages: list[list[str]]) -> list[tuple[int, list[str]]]:
    total = len(pages)
    if total <= 60:
        return [(index, page) for index, page in enumerate(pages, start=1)]
    chosen = [(index, pages[index - 1]) for index in range(1, 31)]
    start = total - 29
    chosen.extend((index, pages[index - 1]) for index in range(start, total + 1))
    return chosen


def render_html(selected: list[tuple[int, list[str]]], mono: bool) -> str:
    family = (
        'Consolas, "Microsoft YaHei", monospace'
        if mono
        else 'SimSun, "NSimSun", "Microsoft YaHei", serif'
    )
    size = "9pt" if mono else "10.5pt"
    line_height = "5.05mm" if mono else "7.05mm"
    blocks: list[str] = []
    for index, (number, lines) in enumerate(selected):
        last = " last" if index == len(selected) - 1 else ""
        body = "\n".join(
            f'<div class="ln">{html.escape(line) if line else "&nbsp;"}</div>'
            for line in lines
        )
        blocks.append(
            f'<section class="page{last}">'
            f'<div class="head"><span>{html.escape(HEADER)}</span>'
            f"<span>第 {number} 页</span></div>"
            f'<div class="body">{body}</div></section>'
        )
    return f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<title>{html.escape(HEADER)}</title>
<style>
  @page {{ size: A4; margin: 0; }}
  html, body {{ margin: 0; padding: 0; background: #fff; color: #000; }}
  .page {{
    width: 210mm;
    height: 296.8mm;
    box-sizing: border-box;
    padding: 11mm 14mm 8mm 14mm;
    overflow: hidden;
    break-after: page;
    page-break-after: always;
  }}
  .page.last {{ break-after: auto; page-break-after: auto; }}
  .head {{
    height: 8mm;
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    border-bottom: 0.25mm solid #000;
    font-family: SimSun, "NSimSun", "Microsoft YaHei", serif;
    font-size: 10.5pt;
    line-height: 1;
    padding-bottom: 1.2mm;
    margin-bottom: 3mm;
  }}
  .body {{
    font-family: {family};
    font-size: {size};
    line-height: {line_height};
  }}
  .ln {{
    height: {line_height};
    white-space: pre;
    overflow: hidden;
  }}
</style>
</head>
<body>
{''.join(blocks)}
</body>
</html>
"""


def find_browser() -> Path:
    candidates = [
        Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
        Path(r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"),
        Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
        Path(r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"),
    ]
    for path in candidates:
        if path.exists():
            return path
    found = shutil.which("msedge") or shutil.which("chrome")
    if found:
        return Path(found)
    raise FileNotFoundError("未找到 Edge 或 Chrome，无法打印 PDF")


def print_pdf(browser: Path, html_path: Path, pdf_path: Path) -> None:
    if pdf_path.exists():
        pdf_path.unlink()
    user_data = Path(tempfile.mkdtemp(prefix="copyright-pdf-"))
    try:
        subprocess.run(
            [
                str(browser),
                "--headless=new",
                "--disable-gpu",
                "--no-first-run",
                "--no-pdf-header-footer",
                f"--user-data-dir={user_data}",
                f"--print-to-pdf={pdf_path}",
                html_path.resolve().as_uri(),
            ],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    finally:
        shutil.rmtree(user_data, ignore_errors=True)
    if not pdf_path.exists() or pdf_path.stat().st_size < 1000:
        raise RuntimeError(f"没有生成 PDF：{pdf_path}")


def main() -> None:
    files = collect_sources()
    code, physical = source_lines(files)
    doc = document_lines(files)
    code_pages = paginate(code, CODE_LINES)
    doc_pages = paginate(doc, DOC_LINES)
    code_selected = select_pages(code_pages)
    doc_selected = select_pages(doc_pages)

    OUT.mkdir(parents=True, exist_ok=True)
    code_html = OUT / "_program.html"
    doc_html = OUT / "_document.html"
    code_pdf = OUT / f"{NAME}{VERSION}-程序鉴别材料.pdf"
    doc_pdf = OUT / f"{NAME}{VERSION}-文档鉴别材料.pdf"
    code_html.write_text(render_html(code_selected, mono=True), encoding="utf-8")
    doc_html.write_text(render_html(doc_selected, mono=False), encoding="utf-8")

    browser = find_browser()
    print_pdf(browser, code_html, code_pdf)
    print_pdf(browser, doc_html, doc_pdf)
    code_html.unlink(missing_ok=True)
    doc_html.unlink(missing_ok=True)

    stats = OUT / "材料说明.txt"
    code_tail = code_pages[-1]
    stats.write_text(
        "\n".join(
            [
                f"软件名称：{NAME}",
                f"版本号：{VERSION}",
                f"源文件数：{len(files)}",
                f"源程序原行数（不含文件名行，空行已合并）：{physical}",
                f"排版后行数（含文件名行和折行）：{len(code)}",
                f"程序总页数：{len(code_pages)}",
                f"程序鉴别材料页码：{[number for number, _ in code_selected]}",
                f"程序最后一页行数：{len(code_tail)}",
                f"说明书排版行数：{len(doc)}",
                f"说明书总页数：{len(doc_pages)}",
                f"文档鉴别材料页码：{[number for number, _ in doc_selected]}",
                f"程序 PDF：{code_pdf}",
                f"文档 PDF：{doc_pdf}",
                "源程序量建议填 22420。这是排版后的行数，与最后一页页码一致：共 449 页，末页 20 行。",
                "登记表里如果还写着 27179，需要改成 22420。",
                "除最后一页外，程序每页 50 行。文档共 21 页，不足 60 页，因此提交全文，每页 32 行。",
            ]
        ),
        encoding="utf-8",
    )
    print(stats.read_text(encoding="utf-8"))


if __name__ == "__main__":
    main()
