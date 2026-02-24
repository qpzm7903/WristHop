# 敲敲计 (TapCare) - 开发完成报告

## 项目概况

基于 HarmonyOS API 12 / HarmonyOS 5.0 开发的 GT 4 手表敲打练习应用。

## 已完成功能

### ✅ 核心服务层

| 文件 | 功能 | 状态 |
|------|------|------|
| `models/TapDataModels.ets` | 数据模型（TapRecord, TapSession, BodyPart, SessionState 等） | ✅ 完成 |
| `services/TapDetector.ets` | 多特征融合敲打检测算法 | ✅ 完成 |
| `services/TapDetectionService.ets` | 传感器订阅管理 | ✅ 完成 |
| `services/CalibrationService.ets` | 左右手校准和基准加速度校准 | ✅ 完成 |
| `services/SessionManager.ets` | 会话状态机管理 | ✅ 完成 |
| `services/DataStorageService.ets` | 数据持久化（Preferences） | ✅ 完成 |
| `services/PermissionService.ets` | 传感器权限管理 | ✅ 完成 |

### ✅ UI 组件层

| 文件 | 功能 | 状态 |
|------|------|------|
| `common/DeviceAdapter.ets` | 圆形表盘适配（466x466） | ✅ 完成 |
| `common/ThemeManager.ets` | 深色模式主题管理 | ✅ 完成 |
| `components/AdaptiveComponents.ets` | 自适应 UI 组件 | ✅ 完成 |
| `pages/Index.ets` | 主界面（敲打计数） | ✅ 完成 |

### ✅ 配置文件

| 文件 | 修改内容 | 状态 |
|------|----------|------|
| `module.json5` | 添加传感器权限声明 | ✅ 完成 |
| `string.json` | 添加权限描述文本 | ✅ 完成 |

---

## 技术亮点

### 1. 多特征融合检测算法

```typescript
// TapDetector.ets
// 敲打特征：加速度突变 + 陀螺仪稳定（手腕相对静止）
if (
  accelDelta > ACCEL_THRESHOLD &&   // 加速度变化 > 15 m/s²
  gyroMag < GYRO_THRESHOLD          // 陀螺仪 < 2 rad/s
) {
  // 判定为敲打开始
}
```

**核心参数：**
- 加速度阈值：15.0 m/s²
- 陀螺仪阈值：2.0 rad/s
- 防抖时间：200ms
- 敲打时长范围：50-300ms
- 峰值加速度要求：> 18 m/s²

### 2. 会话状态机

```
IDLE → COUNTING → COMPLETED
         ↓
       PAUSED ↔ RESUME
```

**状态：**
- `IDLE`: 空闲，未开始
- `COUNTING`: 正在计数
- `PAUSED`: 已暂停
- `COMPLETED`: 已完成目标

### 3. 校准流程

```typescript
// 静止校准 - 采集 50 个样本（2.5 秒 @ 20Hz）
const result = await calibrationService.startCalibration();
// 返回：佩戴手、基准加速度、校准时间戳
```

---

## 项目结构

```
entry/src/main/ets/
├── common/
│   ├── DeviceAdapter.ets      # 设备适配（圆形表盘）
│   └── ThemeManager.ets       # 主题管理（深色模式）
├── components/
│   └── AdaptiveComponents.ets # 自适应 UI 组件
├── models/
│   └── TapDataModels.ets      # 数据模型定义
├── pages/
│   └── Index.ets              # 主界面
└── services/
    ├── CalibrationService.ets     # 校准服务
    ├── DataStorageService.ets     # 数据持久化
    ├── PermissionService.ets      # 权限管理
    ├── SessionManager.ets         # 会话状态机
    ├── TapDetectionService.ets    # 传感器服务
    └── TapDetector.ets            # 敲打检测算法
```

---

## 使用指南

### 1. 开发环境要求

- **操作系统**: Windows 10/11 64-bit
- **IDE**: DevEco Studio 5.0+
- **SDK**: HarmonyOS API 12+
- **目标设备**: HUAWEI GT 4（466x466 圆形表盘）

### 2. 构建和运行

```bash
# 1. 用 DevEco Studio 打开项目
# 2. 登录华为开发者账号
# 3. 连接 GT 4 真机（USB 调试）
# 4. 点击运行按钮
```

### 3. 使用流程

1. **首次启动**：点击「校准」按钮完成校准
2. **选择部位**：点击部位标签切换（左胆经/右胆经/心包经/三焦经）
3. **开始练习**：点击「开始」按钮，开始敲打计数
4. **暂停/继续**：点击「暂停」暂停计数，点击「继续」恢复
5. **结束练习**：点击「结束」停止当前会话

### 4. 振动反馈

每次成功检测到敲打时，手表会振动 50ms 提供触觉反馈。

---

## API 使用说明

### TapDetectionService

```typescript
import { TapDetectionService } from './services/TapDetectionService';

const tapService = TapDetectionService.getInstance();

// 设置敲打回调
tapService.setOnTapCallback((tapRecord: TapRecord) => {
  console.info(`Tap detected: force=${tapRecord.force}`);
});

// 启动检测
tapService.startDetection();

// 停止检测
tapService.stopDetection();
```

### SessionManager

```typescript
import { SessionManager } from './services/SessionManager';

const sessionManager = SessionManager.getInstance();

// 设置目标次数
sessionManager.setTarget(100);

// 设置状态回调
sessionManager.setOnStateChange((state, data) => {
  console.info(`State: ${state}, Count: ${data.currentCount}`);
});

// 开始会话
sessionManager.transition(SessionEvent.START);

// 获取进度
const progress = sessionManager.getProgress(); // 0-100
```

### CalibrationService

```typescript
import { CalibrationService } from './services/CalibrationService';

const calibrationService = CalibrationService.getInstance();

// 开始校准（返回 CalibrationResult）
const result = await calibrationService.startCalibration();
console.info(`Calibrated: hand=${result.wearingHand}`);
```

---

## 数据模型

### TapRecord（敲打记录）

```typescript
interface TapRecord {
  id: string;                    // 唯一标识
  timestamp: number;             // 时间戳
  part: BodyPart;                // 部位
  force: number;                 // 力度值 (0-100)
  forceLevel: ForceLevel;        // 力度等级
  confidence: number;            // 检测置信度 (0-1)
  sessionId: string;             // 所属会话 ID
  accelerometerData?: {          // 原始加速度数据
    x: number;
    y: number;
    z: number;
  };
}
```

### UserSettings（用户设置）

```typescript
interface UserSettings {
  wearingHand: 'left' | 'right'; // 佩戴手
  targetPerSession: number;      // 每次目标（默认 100）
  targetPerDay: number;          // 每日目标（默认 300）
  hapticFeedback: boolean;       // 触觉反馈
  hapticIntensity: number;       // 反馈强度 (1-3)
  soundFeedback: boolean;        // 声音反馈
  reminder: {                    // 提醒设置
    enabled: boolean;
    time: string;                // HH:mm
    message: string;
  };
  sensitivity: number;           // 检测灵敏度 (0.5-2.0)
  calibration: CalibrationResult | null;
}
```

---

## 权限说明

### 必要权限

```json5
{
  "name": "ohos.permission.ACCELEROMETER",
  "reason": "需要加速度传感器权限来检测敲打动作",
  "usedScene": {
    "abilities": ["EntryAbility"],
    "when": "inuse"
  }
}
```

```json5
{
  "name": "ohos.permission.GYROSCOPE",
  "reason": "需要陀螺仪传感器权限来提高敲打检测准确率",
  "usedScene": {
    "abilities": ["EntryAbility"],
    "when": "inuse"
  }
}
```

```json5
{
  "name": "ohos.permission.VIBRATE",
  "reason": "需要振动权限提供敲打反馈",
  "usedScene": {
    "abilities": ["EntryAbility"],
    "when": "inuse"
  }
}
```

---

## 后续优化建议

### 🔴 高优先级

1. **真实数据验证**
   - 在 GT 4 真机上测试敲打检测准确率
   - 根据实际数据调整检测阈值

2. **数据持久化增强**
   - 实现完整的关系型数据库存储
   - 添加历史会话查询功能

3. **错误处理完善**
   - 添加传感器异常恢复逻辑
   - 增加低电量检测

### 🟡 中优先级

4. **UI 优化**
   - 添加敲打动画效果
   - 增加统计图表（力度分布、节奏评分）

5. **后台运行**
   - 使用 Background Tasks API 保持后台检测
   - 添加锁屏状态下运行支持

6. **数据导出**
   - 支持导出 CSV/PDF 练习报告
   - 未来可同步到手机端

### 🟢 低优先级

7. **主题定制**
   - 允许用户自定义主题颜色
   - 添加更多表盘样式

8. **社交功能**
   - 添加练习排行榜
   - 支持分享练习成果

---

## 注意事项

⚠️ **重要提示**：

1. **真机调试**：必须使用华为 GT 4 真机调试，模拟器不支持传感器
2. **签名配置**：需要在 DevEco Studio 中配置华为开发者账号签名
3. **传感器采样率**：当前设置为 20Hz（50ms 间隔），可根据实际需求调整
4. **校准必要性**：首次使用必须完成校准，否则检测准确率会受影响

---

## 参考资料

- [HarmonyOS SensorServiceKit 文档](https://developer.huawei.com/consumer/cn/doc/)
- [TapCare PRD 补充文档](./TapCare_PRD_Supplement.md)
- [HarmonyOS API 12 开发指南](https://developer.huawei.com/consumer/cn/doc/)

---

*开发完成日期：2026 年 2 月 24 日*  
*版本：V1.0.0*
