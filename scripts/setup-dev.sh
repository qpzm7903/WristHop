#!/bin/bash
# WristHop - DevEco Studio 环境设置脚本
# 用于在 macOS 上安装和配置 HarmonyOS 开发环境

set -e

echo "=========================================="
echo "WristHop - HarmonyOS 开发环境设置"
echo "=========================================="
echo ""

# 检查系统
if [[ "$(uname)" != "Darwin" ]]; then
    echo "⚠️  此脚本仅支持 macOS 系统"
    echo "   Windows/Linux 用户请手动安装 DevEco Studio"
    exit 1
fi

# 检查 Node.js
echo "📦 检查 Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo "✅ Node.js 已安装：$NODE_VERSION"
else
    echo "❌ Node.js 未安装"
    echo "   请访问 https://nodejs.org/ 下载安装"
    exit 1
fi

# 检查 npm
echo "📦 检查 npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    echo "✅ npm 已安装：$NPM_VERSION"
else
    echo "❌ npm 未安装"
    exit 1
fi

# 检查 DevEco Studio
echo ""
echo "🔍 检查 DevEco Studio..."
DEVICO_PATH="/Applications/DevEco Studio.app"

if [ -d "$DEVICO_PATH" ]; then
    echo "✅ DevEco Studio 已安装"
    
    # 检查 hvigorw
    HVIGORW_PATH="$DEVICO_PATH/Contents/tools/hvigorw"
    if [ -f "$HVIGORW_PATH" ]; then
        echo "✅ hvigorw 已找到"
        
        # 创建符号链接到 /usr/local/bin
        if [ ! -f "/usr/local/bin/hvigorw" ]; then
            echo "📎 创建 hvigorw 符号链接..."
            sudo ln -sf "$HVIGORW_PATH" "/usr/local/bin/hvigorw"
            echo "✅ hvigorw 已添加到 PATH"
        else
            echo "✅ hvigorw 已在 PATH 中"
        fi
    else
        echo "⚠️  hvigorw 未找到，可能 DevEco Studio 安装不完整"
    fi
    
    # 检查 ohpm
    OHPM_PATH="$DEVICO_PATH/Contents/tools/ohpm"
    if [ -f "$OHPM_PATH" ]; then
        echo "✅ ohpm 已找到"
        
        if [ ! -f "/usr/local/bin/ohpm" ]; then
            echo "📎 创建 ohpm 符号链接..."
            sudo ln -sf "$OHPM_PATH" "/usr/local/bin/ohpm"
            echo "✅ ohpm 已添加到 PATH"
        fi
    fi
else
    echo ""
    echo "❌ DevEco Studio 未安装"
    echo ""
    echo "=========================================="
    echo "安装步骤："
    echo "=========================================="
    echo ""
    echo "1. 访问华为开发者官网："
    echo "   https://developer.huawei.com/consumer/cn/deveco-studio/"
    echo ""
    echo "2. 下载 DevEco Studio 5.0+ (macOS ARM64 版本)"
    echo ""
    echo "3. 安装完成后，重新运行此脚本："
    echo "   npm run setup"
    echo ""
    echo "4. 或者手动添加命令行工具到 PATH："
    echo "   sudo ln -s '/Applications/DevEco Studio.app/Contents/tools/hvigorw' /usr/local/bin/hvigorw"
    echo "   sudo ln -s '/Applications/DevEco Studio.app/Contents/tools/ohpm' /usr/local/bin/ohpm"
    echo ""
    
    # 打开下载页面
    echo "🌐 正在打开下载页面..."
    open "https://developer.huawei.com/consumer/cn/deveco-studio/"
    
    exit 1
fi

# 安装 npm 依赖
echo ""
echo "📦 安装 npm 依赖..."
npm install

echo ""
echo "=========================================="
echo "✅ 环境设置完成！"
echo "=========================================="
echo ""
echo "可用命令："
echo "  npm run dev          - 开发模式（需 DevEco Studio）"
echo "  npm run build:debug  - 构建 debug 版本"
echo "  npm run build:release- 构建 release 版本"
echo "  npm run test         - 运行测试（需 DevEco Studio）"
echo "  npm run clean        - 清理构建"
echo ""
echo "下一步："
echo "1. 用 DevEco Studio 打开项目"
echo "2. 配置签名：File → Project Structure → Signing Configs"
echo "3. 连接 GT 4 真机或启动模拟器"
echo "4. 点击运行按钮 ▶"
echo ""
