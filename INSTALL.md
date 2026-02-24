# WristHop 开发环境安装指南

## ✅ 已完成的安装

| 工具 | 状态 | 版本 |
|------|------|------|
| Node.js | ✅ 已安装 | v23.10.0 |
| npm | ✅ 已安装 | 10.9.2 |
| TypeScript | ✅ 已安装 | ^5.0.0 |
| 项目依赖 | ✅ 已安装 | - |

## ❌ 需要手动安装的工具

### DevEco Studio（必需）

**HarmonyOS 应用开发必须使用 DevEco Studio**，这是华为官方提供的集成开发环境。

#### 下载链接
- **官网**: https://developer.huawei.com/consumer/cn/deveco-studio/
- **macOS**: 下载 ARM64 版本（Apple Silicon）或 Intel 版本
- **Windows**: 下载 64 位版本
- **Linux**: 下载 Ubuntu 版本

#### 安装步骤

**macOS:**
```bash
# 1. 下载完成后，解压 DMG 文件
# 2. 将 DevEco Studio.app 拖拽到 Applications 文件夹
# 3. 打开 DevEco Studio

# 4. 运行项目设置脚本（自动配置命令行工具）
npm run setup

# 5. 或者手动配置命令行工具
sudo ln -s '/Applications/DevEco Studio.app/Contents/tools/hvigorw' /usr/local/bin/hvigorw
sudo ln -s '/Applications/DevEco Studio.app/Contents/tools/ohpm' /usr/local/bin/ohpm
```

**Windows:**
1. 运行安装程序
2. 选择安装路径（建议默认）
3. 安装完成后重启电脑
4. 打开 DevEco Studio

**Linux:**
```bash
# 1. 解压下载的 tar.gz 文件
tar -xzf DevEco-Studio-*.tar.gz -C /opt/

# 2. 运行安装脚本
/opt/DevEco-Studio/bin/fs.sh

# 3. 启动 DevEco Studio
/opt/DevEco-Studio/bin/devecostudio.sh
```

---

## 🚀 安装后的配置

### 1. 打开项目

```bash
# 用 DevEco Studio 打开项目
open -a "DevEco Studio" /Users/weiyicheng/workspace/99_yaya/WristHop
```

### 2. 配置签名

1. `File → Project Structure → Signing Configs`
2. 勾选 "Automatically generate signature"
3. 登录华为开发者账号（如果没有需要注册）

### 3. 连接设备

**真机调试（推荐）:**
1. 手表开启开发者模式：`设置 → 关于 → 版本号（连续点击 7 次）`
2. 开启 USB 调试：`设置 → 系统和更新 → 开发者选项 → USB 调试`
3. 使用原装 USB 数据线连接电脑
4. 手表上选择「文件传输」模式

**模拟器:**
1. `Tools → Device Manager`
2. 创建或启动模拟器
3. ⚠️ 注意：模拟器不支持真实传感器数据

### 4. 运行应用

- 点击 DevEco Studio 顶部的运行按钮 ▶
- 或使用命令行：`hvigorw assembleHap --mode module -b debug`

---

## 🧪 运行测试

### 在 DevEco Studio 中

1. 右键点击 `entry/src/test/ets/` 目录
2. 选择 `Run 'Unit Tests'`

### 命令行（需要 hvigor 配置）

```bash
# 运行所有测试
npm test

# 或使用 hvigorw
hvigorw test --module entry

# 运行单个测试文件
hvigorw test --module entry --tests "**/TapDetector.test.ets"
```

---

## 📝 可用命令

| 命令 | 说明 | 环境要求 |
|------|------|----------|
| `npm run setup` | 运行环境设置脚本 | macOS |
| `npm run dev` | 开发模式 | DevEco Studio |
| `npm run build:debug` | 构建 debug 版本 | DevEco Studio |
| `npm run build:release` | 构建 release 版本 | DevEco Studio |
| `npm test` | 运行测试 | DevEco Studio |
| `npm run lint` | 代码检查 | DevEco Studio |
| `npm run clean` | 清理构建 | 任何环境 |

---

## ⚠️ 常见问题

### 1. "hvigorw: command not found"

**解决方案**: 运行 `npm run setup` 或手动创建符号链接：
```bash
sudo ln -s '/Applications/DevEco Studio.app/Contents/tools/hvigorw' /usr/local/bin/hvigorw
```

### 2. 签名失败

**解决方案**:
1. 确认已登录华为开发者账号
2. 检查网络连接
3. 重新生成签名：`File → Project Structure → Signing Configs → Delete → Create`

### 3. 传感器无数据

**解决方案**:
- 必须使用真机调试（模拟器不支持传感器）
- 确认已授予传感器权限
- 检查手表是否佩戴正确

### 4. USB 连接失败

**解决方案**:
1. 使用原装数据线
2. 手表选择「文件传输」模式
3. 重新插拔 USB
4. 重启 DevEco Studio

---

## 📚 参考文档

- [DevEco Studio 官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/devecostudio-guide-V5)
- [HarmonyOS 开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-self-learning)
- [项目 AGENTS.md](./AGENTS.md) - 开发指南
- [项目 DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) - 详细 API 文档

---

*最后更新：2026 年 2 月 24 日*
