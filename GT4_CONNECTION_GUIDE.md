# GT 4 真机调试连接指南

## 📋 准备工作

### 必需物品
- [ ] HUAWEI GT 4 手表
- [ ] 原装 USB 数据线（或支持数据传输的第三方线）
- [ ]  Windows 10/11 电脑
- [ ] 华为开发者账号（需实名认证）

---

## 🔧 第一步：手表端设置

### 1. 开启开发者模式

```
手表端操作：
设置 → 关于 → 连续点击"版本号" 7 次
```

**详细说明：**
1. 按表冠进入应用列表
2. 找到并点击「设置」图标（⚙️）
3. 向下滑动找到「关于」
4. 点击「版本号」
5. 连续快速点击 7 次
6. 屏幕提示「您已处于开发者模式」
7. 可能需要输入锁屏密码确认

### 2. 开启 USB 调试

```
手表端操作：
设置 → 系统和更新 → 开发人员选项 → USB 调试 → 开启
```

**详细说明：**
1. 返回「设置」主菜单
2. 找到「系统和更新」
3. 点击进入后找到「开发人员选项」
4. 开启「USB 调试」开关
5. 弹出确认对话框 → 点击「允许」

### 3. 开启 ADB 调试（如需要）

某些固件版本需要额外开启 ADB：

```
拨号盘输入：*#*#2846579#*#* → 工程菜单 → 后台设置 → USB 端口设置 → 选择「制造模式」
```

---

## 🔧 第二步：电脑端配置

### 1. 安装华为手机助手（HiSuite）

**下载链接：**
```
https://consumer.huawei.com/cn/support/hisuite/
```

**安装步骤：**
1. 下载 HiSuite 安装包
2. 运行安装程序
3. 按提示完成安装
4. 安装完成后**先不要打开**

### 2. 安装 DevEco Studio USB 驱动

**方法一：通过 DevEco Studio 安装**

1. 打开 DevEco Studio
2. 进入 `Tools → Device Manager`
3. 点击「Driver」标签页
4. 点击「Install Driver」
5. 按向导完成安装

**方法二：手动安装**

1. 找到 DevEco Studio 安装目录
2. 进入 `sdk-tools\driver` 文件夹
3. 右键 `hwusb.inf` → 安装

### 3. 检查驱动安装

```powershell
# 打开设备管理器
devmgmt.msc

# 查看是否有以下设备：
- HUAWEI Mobile Broadband
- Android Composite ADB Interface
- Huawei USB Composite Device
```

如有黄色感叹号，需要重新安装驱动。

---

## 🔧 第三步：连接手表

### 物理连接

1. **使用原装数据线**连接手表和电脑
   - GT 4 使用无线充电底座，需要 USB 线连接底座
   - 确保数据线支持数据传输（不仅是充电）

2. **手表端选择连接模式**
   - 连接后手表会弹出 USB 选项
   - 选择「文件传输」或「MTP」模式
   - 如没有弹出，下拉通知栏手动选择

### 验证连接

**方法一：命令行验证**

```powershell
# 打开命令提示符
cd D:\DevTools\DevEco Studio\sdk\platform-tools

# 输入命令
adb devices

# 成功输出示例：
List of devices attached
ABC123456789    device
```

**方法二：DevEco Studio 验证**

1. 打开 DevEco Studio
2. 点击顶部工具栏设备下拉框
3. 应该能看到已连接的 GT 4 设备

---

## 🔧 第四步：DevEco Studio 配置

### 1. 登录华为开发者账号

```
DevEco Studio → File → Settings → HarmonyOS SDK → 登录
```

**详细说明：**
1. 打开 DevEco Studio
2. `File` → `Settings`（或按 `Ctrl+Alt+S`）
3. 左侧选择 `HarmonyOS SDK`
4. 点击右上角登录图标
5. 使用华为开发者账号登录
6. 完成实名认证验证

### 2. 配置签名

**自动签名（推荐新手）：**

1. 打开项目 `entry` 模块的 `build-profile.json5`
2. 确保 `signingConfig` 设置为 `"default"`
3. 首次运行时会自动创建签名配置

**手动签名：**

1. `File` → `Project Structure`
2. 选择 `Project` → `Signing Configs`
3. 勾选 `Automatically generate signature`
4. 或手动配置签名文件

### 3. 选择设备

1. 点击顶部工具栏的运行配置下拉框
2. 选择 `entry`
3. 设备列表中选择你的 GT 4
4. 点击运行按钮（绿色三角形）

---

## 🔧 第五步：运行应用

### 首次部署

1. 确保手表屏幕处于点亮状态
2. 点击 DevEco Studio 的运行按钮
3. 手表端可能弹出「允许调试」对话框 → 点击「允许」
4. 等待应用安装完成
5. 应用自动启动

### 查看日志

```
DevEco Studio → View → Tool Windows → Run
```

或使用命令行：

```powershell
hdc shell hilog
```

---

## ⚠️ 常见问题解决

### 问题 1：电脑无法识别手表

**解决方案：**
1. 更换 USB 数据线（必须是数据线）
2. 更换 USB 端口（尝试 USB 3.0）
3. 重启电脑和手表
4. 重新安装 HiSuite 驱动
5. 在设备管理器中卸载未知设备后重新扫描

### 问题 2：adb devices 显示 unauthorized

**解决方案：**
1. 手表端撤销 USB 调试授权
2. 重新连接数据线
3. 手表端会弹出新的授权请求 → 点击「允许」
4. 再次运行 `adb devices`

### 问题 3：DevEco Studio 找不到设备

**解决方案：**
1. 确认手表已开启 USB 调试
2. 确认 HiSuite 驱动已安装
3. 重启 DevEco Studio
4. 在 Device Manager 中刷新设备列表
5. 检查 `local.properties` 中的 SDK 路径

### 问题 4：应用安装失败

**错误信息：** `Install failed: Device not found`

**解决方案：**
1. 检查手表电量（建议 50% 以上）
2. 确认手表开发者模式已开启
3. 重启手表后重新连接
4. 检查签名配置是否正确

### 问题 5：传感器权限被拒绝

**解决方案：**
1. 手表端：设置 → 隐私 → 权限管理
2. 找到「敲敲计」应用
3. 开启传感器权限
4. 重新运行应用

---

## 🔍 调试技巧

### 查看传感器数据

```typescript
// 在代码中添加调试日志
console.info(`Accelerometer: x=${data.x}, y=${data.y}, z=${data.z}`);
```

在 DevEco Studio 的 Run 窗口查看输出。

### 使用 HDC 命令

```powershell
# 查看连接的设备
hdc list targets

# 进入设备 shell
hdc shell

# 查看应用日志
hdc shell hilog

# 安装应用
hdc install entry-default-signed.hap

# 卸载应用
hdc shell bm uninstall com.example.tapcare

# 查看设备信息
hdc shell getprop
```

### 性能分析

```
DevEco Studio → Tools → Profiler
```

可以查看：
- CPU 使用率
- 内存占用
- 能耗情况
- 传感器数据流

---

## 📱 手表端快捷操作

### 强制关闭应用

```
设置 → 应用管理 → 敲敲计 → 强行停止
```

### 清除应用数据

```
设置 → 应用管理 → 敲敲计 → 存储 → 清除数据
```

### 查看应用版本

```
设置 → 应用管理 → 敲敲计 → 版本号
```

---

## ✅ 连接成功检查清单

- [ ] 手表开发者模式已开启
- [ ] USB 调试已开启
- [ ] 数据线连接稳定
- [ ] 电脑已安装 HiSuite 驱动
- [ ] `adb devices` 能显示设备
- [ ] DevEco Studio 设备列表中有 GT 4
- [ ] 华为开发者账号已登录
- [ ] 签名配置已完成
- [ ] 应用能成功安装到手表
- [ ] 应用能正常启动

---

## 📞 获取帮助

如果以上步骤都无法解决问题：

1. **华为开发者论坛**
   - https://developer.huawei.com/consumer/cn/forum/

2. **HarmonyOS 开发者文档**
   - https://developer.huawei.com/consumer/cn/doc/

3. **DevEco Studio 帮助**
   - `Help` → `Check for Updates`
   - `Help` → `Diagnostic Tools`

---

*最后更新：2026 年 2 月 24 日*
