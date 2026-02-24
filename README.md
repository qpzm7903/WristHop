# WristHop (敲敲计)

基于 HarmonyOS 5.0 / API 12 开发的 HUAWEI GT 4 手表敲打练习应用。

## 📱 项目简介

**敲敲计 (TapCare)** 是一款健康练习应用，通过手表内置的加速度计和陀螺仪传感器，精准检测用户的敲打动作，帮助进行中医经络敲打练习。

### 核心功能

- ✅ **多特征融合检测算法** - 加速度 + 陀螺仪融合，准确区分敲打与甩手/拍手
- ✅ **智能力度识别** - 0-100 力度等级（轻/中/重）
- ✅ **左右手自动校准** - 自动检测佩戴手，个性化检测参数
- ✅ **会话状态机管理** - 支持开始/暂停/恢复/完成状态
- ✅ **数据持久化** - 本地存储练习记录和统计数据
- ✅ **深色模式 UI** - 圆形表盘适配，省电优化

### 支持部位

- 左胆经 / 右胆经
- 心包经
- 三焦经
- 自定义部位

---

## 🛠️ 技术栈

| 技术 | 版本 |
|------|------|
| HarmonyOS | 5.0.0.77 |
| API Level | 12+ |
| 开发框架 | ArkTS |
| 目标设备 | HUAWEI GT 4 (466x466) |
| 传感器 | 加速度计 + 陀螺仪 |

---

## 📦 项目结构

```
WristHop/
├── entry/src/main/ets/
│   ├── common/              # 通用工具
│   │   ├── DeviceAdapter.ets    # 设备适配（圆形表盘）
│   │   └── ThemeManager.ets     # 主题管理（深色模式）
│   ├── components/          # UI 组件
│   │   └── AdaptiveComponents.ets
│   ├── models/              # 数据模型
│   │   └── TapDataModels.ets
│   ├── pages/               # 页面
│   │   └── Index.ets            # 主界面
│   └── services/            # 服务层
│       ├── CalibrationService.ets   # 校准服务
│       ├── DataStorageService.ets   # 数据持久化
│       ├── PermissionService.ets    # 权限管理
│       ├── SessionManager.ets       # 会话状态机
│       ├── TapDetectionService.ets  # 传感器服务
│       └── TapDetector.ets          # 敲打检测算法
├── DEVELOPMENT_GUIDE.md     # 开发指南
├── GT4_CONNECTION_GUIDE.md  # GT 4 连接指南
└── TapCare_PRD_Supplement.md # PRD 文档
```

---

## 🚀 快速开始

### 环境要求

- **IDE**: DevEco Studio 5.0+
- **SDK**: HarmonyOS API 12+
- **系统**: Windows 10/11, macOS 10.15+, 或 Linux (Ubuntu 20.04+)
- **设备**: HUAWEI GT 4（真机调试）或本地模拟器

### 安装步骤

```bash
# 1. 克隆项目
git clone git@github.com:qpzm7903/WristHop.git
cd WristHop

# 2. 用 DevEco Studio 打开项目

# 3. 配置签名
File → Project Structure → Signing Configs
→ 勾选 "Automatically generate signature"

# 4. 连接 GT 4 真机（或启动模拟器）

# 5. 运行应用
点击运行按钮 ▶
```

### 首次使用

1. **完成校准**：点击「校准」按钮，静止站立 3 秒
2. **选择部位**：点击部位标签切换
3. **开始练习**：点击「开始」，开始敲打计数

---

## 🔧 开发指南

### 真机调试配置

详见 [GT4_CONNECTION_GUIDE.md](./GT4_CONNECTION_GUIDE.md)

```
1. 手表开启开发者模式
2. 开启 USB 调试
3. USB 连接电脑
4. DevEco Studio 运行
```

### 核心算法

敲打检测采用**多特征融合算法**：

```typescript
// 判定条件
if (
  accelDelta > 15.0 &&    // 加速度突变 > 15 m/s²
  gyroMag < 2.0 &&        // 陀螺仪稳定 < 2 rad/s
  duration 50-300ms &&    // 时长合理
  maxAccel > 18.0         // 峰值达标
) {
  // 判定为有效敲打
}
```

详见 [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)

---

## 📄 文档

| 文档 | 说明 |
|------|------|
| [TapCare_PRD_Supplement.md](./TapCare_PRD_Supplement.md) | 完整 PRD 文档 |
| [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) | 开发指南和 API 说明 |
| [GT4_CONNECTION_GUIDE.md](./GT4_CONNECTION_GUIDE.md) | GT 4 真机连接指南 |

---

## 📱 权限说明

| 权限 | 用途 |
|------|------|
| `ohos.permission.ACCELEROMETER` | 加速度传感器检测敲打动作 |
| `ohos.permission.GYROSCOPE` | 陀螺仪提高检测准确率 |
| `ohos.permission.VIBRATE` | 振动反馈 |

---

## ⚠️ 注意事项

1. **真机调试推荐**：模拟器不支持真实传感器数据
2. **必须校准**：首次使用需完成校准以确保准确率
3. **签名配置**：需要华为开发者账号进行真机调试
4. **USB 连接**：使用原装数据线，选择「文件传输」模式

---

## 📈 后续优化

- [ ] 历史数据统计和图表展示
- [ ] 后台运行支持
- [ ] 数据导出（CSV/PDF）
- [ ] 手机 App 同步
- [ ] 社交功能（排行榜）

---

## 📞 问题反馈

如有问题，请提交 [GitHub Issues](https://github.com/qpzm7903/WristHop/issues)

---

## 📄 许可证

MIT License

---

*开发完成日期：2026 年 2 月 24 日*  
*版本：V1.0.0*
