#!/bin/bash

# 编译并拷贝 flutter_floating_demo 到 talix_companion_flutter
# 作者: Kiro
# 日期: 2026-07-30

set -e  # 遇到错误立即退出

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}====================================${NC}"
echo -e "${YELLOW}Flutter Floating Demo 编译脚本${NC}"
echo -e "${YELLOW}====================================${NC}"

# 项目路径
FLOATING_PROJECT="C:/Users/LSM/Documents/Code/TailxConnect/talix_desktop_floating_ball"
TARGET_DIR="C:/Users/LSM/OneDrive - Lenovo/Documents/PGB/win/release/floating"

# 切换到项目目录
echo -e "${GREEN}[1/4] 切换到项目目录...${NC}"
cd "$FLOATING_PROJECT"

# 清理旧的构建
echo -e "${GREEN}[2/4] 清理旧的构建文件...${NC}"
flutter clean

# 编译 Windows Release 版本
echo -e "${GREEN}[3/4] 开始编译 Windows Release 版本...${NC}"
flutter build windows --release

# 检查编译是否成功
BUILD_OUTPUT="$FLOATING_PROJECT/build/windows/x64/runner/Release"
if [ ! -d "$BUILD_OUTPUT" ]; then
    echo -e "${RED}编译失败！找不到输出目录: $BUILD_OUTPUT${NC}"
    exit 1
fi

# 结束正在运行的悬浮球进程，否则 dll 被占用会导致拷贝失败（共享冲突）
echo -e "${GREEN}[4/4] 拷贝文件到目标目录...${NC}"
echo -e "  - 关闭正在运行的悬浮球（如果有）..."
taskkill /F /IM talix_desktop_floating_ball.exe >/dev/null 2>&1 || true
sleep 1

# 创建目标目录
mkdir -p "$TARGET_DIR"

# 拷贝所有编译产物
echo -e "  - 正在拷贝文件..."
cp -r "$BUILD_OUTPUT"/* "$TARGET_DIR/"

# 统计文件
FILE_COUNT=$(find "$TARGET_DIR" -type f | wc -l)
echo -e "${GREEN}✓ 编译完成！${NC}"
echo -e "  源目录: $BUILD_OUTPUT"
echo -e "  目标目录: $TARGET_DIR"
echo -e "  已拷贝 ${FILE_COUNT} 个文件"

echo -e "${YELLOW}====================================${NC}"
echo -e "${GREEN}全部完成！${NC}"
echo -e "${YELLOW}====================================${NC}"
