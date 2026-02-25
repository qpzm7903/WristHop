#!/bin/bash

# WristHop 构建脚本
# 用法：./scripts/build.sh [debug|release]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 设置 DevEco Studio 工具路径
export PATH="/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin:$PATH"
export PATH="/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin:$PATH"

cd "$PROJECT_ROOT"

BUILD_MODE="${1:-debug}"

echo "========================================="
echo "WristHop 构建脚本"
echo "========================================="
echo "构建模式：$BUILD_MODE"
echo "项目目录：$PROJECT_ROOT"
echo "========================================="

if [ "$BUILD_MODE" = "debug" ]; then
    echo "开始构建 Debug 版本..."
    hvigorw assembleHap --mode module -p product=default -b debug
elif [ "$BUILD_MODE" = "release" ]; then
    echo "开始构建 Release 版本..."
    hvigorw assembleHap --mode module -p product=default -b release
else
    echo "错误：未知的构建模式 '$BUILD_MODE'"
    echo "用法：$0 [debug|release]"
    exit 1
fi

BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo "========================================="
    echo "✅ 构建成功！"
    echo "输出目录：entry/build/default/outputs/hap/"
    echo "========================================="
else
    echo "========================================="
    echo "❌ 构建失败，退出码：$BUILD_EXIT_CODE"
    echo "========================================="
fi

exit $BUILD_EXIT_CODE
