# 敲敲计 (TapCare) - HarmonyOS Watch PRD 补充文档

> **版本**: V1.0.0  
> **目标设备**: HUAWEI GT 4  
> **鸿蒙版本**: HarmonyOS 5.0.0.77 / API 12  
> **开发框架**: ArkTS + HarmonyOS Kit  
> **发布日期**: 2026年2月

---

## 目录

1. [开发环境搭建指南](#附录-a-windows-10-开发环境搭建指南)
2. [传感器 API 修正](#附录-b-修正后的传感器-api)
3. [敲打检测算法优化](#附录-c-敲打检测算法优化)
4. [左右手校准流程](#附录-d-左右手校准流程)
5. [会话状态机设计](#附录-e-会话状态机设计)
6. [扩展数据模型](#附录-f-扩展数据模型)
7. [错误处理与边界情况](#附录-g-错误处理与边界情况)
8. [UI 适配方案](#附录-h-ui 适配方案)

---

## 附录 A: Windows 10 开发环境搭建指南

### A.1 系统要求

| 项目 | 最低要求 | 推荐配置 |
|------|----------|----------|
| 操作系统 | Windows 10 64-bit | Windows 11 64-bit |
| 内存 | 8GB | 16GB+ |
| 硬盘空间 | 100GB | 200GB+ (含模拟器) |
| 分辨率 | 1280×800 | 1920×1080+ |
| CPU | Intel i5 / AMD Ryzen 5 | Intel i7 / AMD Ryzen 7 |

### A.2 安装步骤

#### 第一步：下载 DevEco Studio

```
官网地址：https://developer.huawei.com/consumer/cn/deveco-studio/
```

1. 登录华为开发者账号（需注册）
2. 下载 `deveco-studio-xxxx.exe` 安装包
3. 当前最新版本：**DevEco Studio 5.0+**

#### 第二步：安装 DevEco Studio

```powershell
# 安装路径建议（避免中文路径）
默认路径：C:\Program Files\Huawei\DevEco Studio
推荐路径：D:\DevTools\DevEco Studio
```

**DevEco Studio 已内置以下内容，无需单独安装：**
- OpenJDK 17
- Node.js
- HarmonyOS SDK
- Hvigor 构建工具
- OHPM 包管理器

#### 第三步：首次启动配置

1. 启动 DevEco Studio
2. 接受许可协议
3. 选择 SDK 安装路径（建议 50GB+ 空间）
4. 下载 HarmonyOS SDK（选择 API 12+）
5. 配置模拟器（可选）

#### 第四步：华为账号登录

```
设置 → 账号管理 → 登录华为账号
```

登录后可使用：
- 真机调试签名
- 云端模拟器
- 应用发布

### A.3 GT 4 真机调试配置

#### 步骤 1：开启开发者模式

```
手表端：设置 → 关于 → 连续点击版本号 7 次 → 输入密码确认
```

#### 步骤 2：连接电脑

1. 使用 USB 数据线连接手表和电脑
2. 手表端选择「文件传输」模式
3. 电脑端安装华为手机助手（HiSuite）驱动

#### 步骤 3：签名配置

```json5
// build-profile.json5
{
  "app": {
    "signingConfigs": [
      {
        "name": "default",
        "type": "HarmonyOS",
        "material": {
          "certpath": "path/to/cert.cer",
          "storePassword": "password",
          "keyAlias": "alias",
          "keyPassword": "password",
          "profile": "path/to/profile.p7b",
          "signAlg": "SHA256withECDSA",
          "verify": true,
          "storeFile": "path/to/keystore.p12"
        }
      }
    ]
  }
}
```

### A.4 常见问题

| 问题 | 解决方案 |
|------|----------|
| SDK 下载失败 | 检查网络，使用华为镜像源 |
| 签名失败 | 确认华为账号已实名认证 |
| 模拟器启动慢 | 分配更多内存（建议 4GB+） |
| USB 连接不识别 | 更新 USB 驱动，重启电脑 |

---

## 附录 B: 修正后的传感器 API

### B.1 正确的导入方式

```typescript
// ❌ 原 PRD 中的旧写法（已废弃）
import { sensor } from '@ohos.sensor';
import { vibrator } from '@ohos.vibrator';

// ✅ HarmonyOS 5.0 / API 12 正确写法
import { sensor } from '@kit.SensorServiceKit';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### B.2 加速度传感器订阅

```typescript
// TapDetectionService.ets - 修正版
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class TapDetectionService {
  private static readonly TAP_THRESHOLD = 12.0;
  private static readonly DEBOUNCE_TIME = 150;
  private lastTapTime: number = 0;
  private tapCount: number = 0;
  private isSubscribed: boolean = false;

  // 启动传感器订阅
  startDetection(): void {
    if (this.isSubscribed) return;
    
    try {
      // interval 单位：纳秒，100000000ns = 100ms = 10Hz
      // 50000000ns = 50ms = 20Hz（推荐省电模式）
      sensor.on(sensor.SensorId.ACCELEROMETER, 
        (data: sensor.AccelerometerResponse) => {
          this.processAccelerometer(data);
        }, 
        { interval: 50000000 } // 50ms 间隔
      );
      this.isSubscribed = true;
      console.info('Accelerometer subscribed successfully');
    } catch (error) {
      const e: BusinessError = error as BusinessError;
      console.error(`Failed to subscribe: Code ${e.code}, ${e.message}`);
    }
  }

  // 停止传感器订阅
  stopDetection(): void {
    if (!this.isSubscribed) return;
    
    try {
      sensor.off(sensor.SensorId.ACCELEROMETER);
      this.isSubscribed = false;
      console.info('Accelerometer unsubscribed');
    } catch (error) {
      const e: BusinessError = error as BusinessError;
      console.error(`Failed to unsubscribe: Code ${e.code}, ${e.message}`);
    }
  }

  private processAccelerometer(data: sensor.AccelerometerResponse): void {
    const magnitude = Math.sqrt(
      data.x * data.x + 
      data.y * data.y + 
      data.z * data.z
    );
    // ... 后续处理逻辑
  }
}
```

### B.3 陀螺仪传感器（辅助判断）

```typescript
// 使用陀螺仪辅助判断手腕转动
startGyroscope(): void {
  try {
    sensor.on(sensor.SensorId.GYROSCOPE, 
      (data: sensor.GyroscopeResponse) => {
        // data.x, data.y, data.z 为角速度
        // 用于判断手腕是否在敲打过程中转动
        this.analyzeWristRotation(data);
      }, 
      { interval: 50000000 }
    );
  } catch (error) {
    const e: BusinessError = error as BusinessError;
    console.error(`Gyroscope error: ${e.code}`);
  }
}
```

### B.4 振动反馈

```typescript
import { vibrator } from '@kit.SensorServiceKit';

// 简单振动
vibrator.vibrate(50); // 振动 50ms

// 或使用振动效果
vibrator.startVibration({
  type: 'time',
  duration: 50
});
```

### B.5 必需权限声明

```json5
// module.json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCELEROMETER",
        "reason": "$string:permission_accelerometer_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.GYROSCOPE",
        "reason": "$string:permission_gyroscope_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.VIBRATE",
        "reason": "$string:permission_vibrate_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

---

## 附录 C: 敲打检测算法优化

### C.1 问题分析

原算法仅使用加速度幅值阈值检测，存在以下问题：

| 问题 | 表现 |
|------|------|
| 误识别甩手 | 正常走路摆手时误触发 |
| 误识别拍手 | 拍手动作与敲打相似 |
| 无法区分力度 | 所有敲打都按同一标准计数 |
| 左右手差异 | 不同佩戴方式信号特征不同 |

### C.2 优化方案：多特征融合检测

```typescript
// TapDetector.ets - 优化版敲打检测器
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface SensorData {
  timestamp: number;
  accelX: number;
  accelY: number;
  accelZ: number;
  gyroX: number;
  gyroY: number;
  gyroZ: number;
}

interface TapEvent {
  timestamp: number;
  force: number;
  confidence: number;
  wristAngle: number;
}

export class TapDetector {
  // 加速度窗口（用于时序分析）
  private accelWindow: SensorData[] = [];
  private static readonly WINDOW_SIZE = 20; // 1 秒窗口 @ 20Hz

  // 检测参数
  private static readonly ACCEL_THRESHOLD = 15.0;  // 加速度阈值
  private static readonly GYRO_THRESHOLD = 2.0;    // 陀螺仪阈值
  private static readonly DEBOUNCE_MS = 200;       // 防抖时间
  private static readonly MIN_TAP_DURATION_MS = 50; // 最小敲打时长
  private static readonly MAX_TAP_DURATION_MS = 300; // 最大敲打时长

  private lastTapTime: number = 0;
  private tapStartTime: number = 0;
  private isInTap: boolean = false;
  private maxAccelDuringTap: number = 0;

  // 手腕佩戴位置（需要校准）
  private wearingHand: 'left' | 'right' = 'left';
  private baselineAccel: { x: number, y: number, z: number } = { x: 0, y: 0, z: -9.8 };

  /**
   * 核心检测算法 - 多特征融合
   */
  processSensorData(
    accel: sensor.AccelerometerResponse, 
    gyro: sensor.GyroscopeResponse
  ): TapEvent | null {
    const now = Date.now();

    // 1. 计算合成加速度
    const accelMagnitude = Math.sqrt(
      accel.x * accel.x + accel.y * accel.y + accel.z * accel.z
    );

    // 2. 计算陀螺仪角速度变化
    const gyroMagnitude = Math.sqrt(
      gyro.x * gyro.x + gyro.y * gyro.y + gyro.z * gyro.z
    );

    // 3. 加速度变化率（相对于基线）
    const accelDelta = this.calculateAccelDelta(accel);

    // 4. 添加到滑动窗口
    this.addToWindow({
      timestamp: now,
      accelX: accel.x, accelY: accel.y, accelZ: accel.z,
      gyroX: gyro.x, gyroY: gyro.y, gyroZ: gyro.z
    });

    // 5. 敲打状态机
    return this.detectTapStateMachine(
      accelMagnitude, 
      gyroMagnitude, 
      accelDelta, 
      now
    );
  }

  private detectTapStateMachine(
    accelMag: number, 
    gyroMag: number, 
    accelDelta: number,
    now: number
  ): TapEvent | null {
    // 状态 1：空闲状态 -> 检测敲打开始
    if (!this.isInTap) {
      // 敲打特征：加速度突变 + 陀螺仪稳定（手腕相对静止）
      if (
        accelDelta > TapDetector.ACCEL_THRESHOLD && 
        gyroMag < TapDetector.GYRO_THRESHOLD
      ) {
        this.isInTap = true;
        this.tapStartTime = now;
        this.maxAccelDuringTap = accelMag;
        console.debug(`Tap started at ${now}`);
      }
      return null;
    }

    // 状态 2：敲打进行中 -> 追踪峰值
    const duration = now - this.tapStartTime;

    if (accelMag > this.maxAccelDuringTap) {
      this.maxAccelDuringTap = accelMag;
    }

    // 状态 3：敲打结束（加速度恢复正常）
    const normalizedAccel = Math.abs(accelMag - 9.8); // 减去重力
    if (
      normalizedAccel < 2.0 || 
      duration > TapDetector.MAX_TAP_DURATION_MS
    ) {
      this.isInTap = false;

      // 验证是否为有效敲打
      if (
        duration >= TapDetector.MIN_TAP_DURATION_MS && 
        duration <= TapDetector.MAX_TAP_DURATION_MS &&
        this.maxAccelDuringTap > 18.0
      ) {
        // 防抖检查
        if (now - this.lastTapTime > TapDetector.DEBOUNCE_MS) {
          this.lastTapTime = now;
          
          return {
            timestamp: now,
            force: this.calculateForce(this.maxAccelDuringTap),
            confidence: this.calculateConfidence(duration, gyroMag),
            wristAngle: this.calculateWristAngle()
          };
        }
      }
      
      this.maxAccelDuringTap = 0;
    }

    return null;
  }

  /**
   * 计算加速度变化（减去重力基线）
   */
  private calculateAccelDelta(accel: sensor.AccelerometerResponse): number {
    const dx = accel.x - this.baselineAccel.x;
    const dy = accel.y - this.baselineAccel.y;
    const dz = accel.z - this.baselineAccel.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /**
   * 计算力度（0-100）
   */
  private calculateForce(maxAccel: number): number {
    // 根据加速度峰值映射到力度等级
    // 15-20: 轻，20-30: 中，30+: 重
    const force = Math.min(100, Math.max(0, (maxAccel - 15) * 4));
    return Math.round(force);
  }

  /**
   * 计算置信度（0-1）
   */
  private calculateConfidence(duration: number, gyroMag: number): number {
    // 理想敲打：时长 100-200ms，陀螺仪变化<1.0
    const durationScore = 1 - Math.abs(duration - 150) / 150;
    const gyroScore = 1 - Math.min(1, gyroMag / 3.0);
    return Math.max(0, Math.min(1, (durationScore + gyroScore) / 2));
  }

  /**
   * 计算手腕角度（用于左手/右手判断）
   */
  private calculateWristAngle(): number {
    // 基于当前加速度方向计算手腕朝向
    return 0; // 简化实现
  }

  private addToWindow(data: SensorData): void {
    this.accelWindow.push(data);
    if (this.accelWindow.length > TapDetector.WINDOW_SIZE) {
      this.accelWindow.shift();
    }
  }

  /**
   * 校准基准加速度（用户静止站立时调用）
   */
  calibrate(accel: sensor.AccelerometerResponse): void {
    // 多次采样取平均
    this.baselineAccel = {
      x: accel.x,
      y: accel.y,
      z: accel.z
    };
    console.info(`Calibrated baseline: ${JSON.stringify(this.baselineAccel)}`);
  }

  /**
   * 设置佩戴手
   */
  setWearingHand(hand: 'left' | 'right'): void {
    this.wearingHand = hand;
  }
}
```

### C.3 检测算法流程图

```
┌─────────────────────────────────────────────────────────────┐
│                    敲打检测状态机                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────┐    加速度突变     ┌──────────────┐           │
│   │  空闲   │ ───────────────▶ │  敲打进行中   │           │
│   │ (Idle)  │   且陀螺仪稳定    │  (Tapping)   │           │
│   └─────────┘                  └──────────────┘           │
│        ▲                              │                    │
│        │                              │ 加速度恢复正常      │
│        │    时长有效 + 峰值达标        │ 或超时             │
│        └──────────────────────────────┘                    │
│                    │                                        │
│                    ▼                                        │
│           ┌──────────────┐                                  │
│           │   输出敲打    │                                  │
│           │   (TapEvent) │                                  │
│           └──────────────┘                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘

判定条件：
┌───────────────────┬────────────────────────────────────────┐
│ 条件              │ 阈值                                   │
├───────────────────┼────────────────────────────────────────┤
│ 加速度突变        │ Δaccel > 15 m/s² (相对于基线)          │
│ 陀螺仪稳定        │ |ω| < 2 rad/s                          │
│ 敲打时长          │ 50ms < duration < 300ms                │
│ 峰值加速度        │ max_accel > 18 m/s²                    │
│ 防抖间隔          │ > 200ms                                │
└───────────────────┴────────────────────────────────────────┘
```

---

## 附录 D: 左右手校准流程

### D.1 为什么需要校准

| 因素 | 左手佩戴 | 右手佩戴 |
|------|----------|----------|
| 加速度基准方向 | z 轴朝向不同 | z 轴朝向相反 |
| 敲打动作特征 | 手掌向下敲打 | 手背向下敲打 |
| 陀螺仪旋转方向 | 顺时针为主 | 逆时针为主 |

### D.2 校准流程设计

```typescript
// CalibrationService.ets
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface CalibrationResult {
  wearingHand: 'left' | 'right';
  baselineAccel: { x: number, y: number, z: number };
  baselineGyro: { x: number, y: number, z: number };
  sensitivity: number;
  calibratedAt: number;
}

export class CalibrationService {
  private samples: Array<{
    accel: sensor.AccelerometerResponse,
    gyro: sensor.GyroscopeResponse
  }> = [];
  
  private static readonly SAMPLE_COUNT = 50; // 采样次数
  private static readonly SAMPLE_INTERVAL = 50000000; // 50ms

  /**
   * 开始校准流程
   * @returns 校准结果
   */
  async startCalibration(): Promise<CalibrationResult> {
    return new Promise((resolve, reject) => {
      this.samples = [];
      
      // 1. 提示用户保持静止
      console.info('请保持手臂自然下垂，静止站立...');
      
      // 2. 采集加速度和陀螺仪数据
      const callback = (accel: sensor.AccelerometerResponse) => {
        this.samples.push({ 
          accel, 
          gyro: { x: 0, y: 0, z: 0 } as sensor.GyroscopeResponse 
        });
        
        if (this.samples.length >= CalibrationService.SAMPLE_COUNT) {
          sensor.off(sensor.SensorId.ACCELEROMETER);
          const result = this.processCalibrationData();
          resolve(result);
        }
      };

      try {
        sensor.on(sensor.SensorId.ACCELEROMETER, callback, 
          { interval: CalibrationService.SAMPLE_INTERVAL });
      } catch (error) {
        reject(error);
      }
    });
  }

  /**
   * 自动检测佩戴手
   * 原理：用户做 3 次「抬起手腕看表」动作，根据陀螺仪方向判断
   */
  async detectWearingHand(): Promise<'left' | 'right'> {
    return new Promise((resolve) => {
      const gyroSamples: sensor.GyroscopeResponse[] = [];
      
      console.info('请抬起手腕看表，然后放下，重复 3 次...');
      
      const callback = (gyro: sensor.GyroscopeResponse) => {
        gyroSamples.push(gyro);
        
        if (gyroSamples.length >= 60) { // 3 秒 @ 20Hz
          sensor.off(sensor.SensorId.GYROSCOPE);
          
          // 分析陀螺仪数据判断左右手
          const avgX = gyroSamples.reduce(
            (sum, g) => sum + g.x, 0
          ) / gyroSamples.length;
          const avgY = gyroSamples.reduce(
            (sum, g) => sum + g.y, 0
          ) / gyroSamples.length;
          
          // 抬腕动作：左手 x 轴正方向，右手 x 轴负方向
          const hand = avgX > 0 ? 'left' : 'right';
          resolve(hand);
        }
      };

      try {
        sensor.on(sensor.SensorId.GYROSCOPE, callback, 
          { interval: CalibrationService.SAMPLE_INTERVAL });
      } catch (error) {
        // 默认左手
        resolve('left');
      }
    });
  }

  private processCalibrationData(): CalibrationResult {
    // 计算加速度平均值作为基线
    const avgAccel = {
      x: this.samples.reduce((sum, s) => sum + s.accel.x, 0) / this.samples.length,
      y: this.samples.reduce((sum, s) => sum + s.accel.y, 0) / this.samples.length,
      z: this.samples.reduce((sum, s) => sum + s.accel.z, 0) / this.samples.length
    };

    // 根据 z 轴方向判断佩戴手（简化判断）
    const wearingHand = avgAccel.z < 0 ? 'left' : 'right';

    return {
      wearingHand,
      baselineAccel: avgAccel,
      baselineGyro: { x: 0, y: 0, z: 0 },
      sensitivity: 1.0, // 默认灵敏度
      calibratedAt: Date.now()
    };
  }
}
```

### D.3 校准 UI 流程

```
┌─────────────────────────────────────────────────────────────┐
│                     校准向导                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   步骤 1/3: 选择佩戴手                                       │
│   ┌─────────┐    ┌─────────┐                                │
│   │  左手   │    │  右手   │                                │
│   │  👈    │    │  👉    │                                │
│   └─────────┘    └─────────┘                                │
│                                                             │
│   步骤 2/3: 静止校准                                         │
│   ┌─────────────────────────────────┐                       │
│   │  请保持手臂自然下垂，            │                       │
│   │  静止站立 3 秒...               │                       │
│   │                                 │                       │
│   │  ████████░░░░░░  60%            │                       │
│   └─────────────────────────────────┘                       │
│                                                             │
│   步骤 3/3: 动作校准                                         │
│   ┌─────────────────────────────────┐                       │
│   │  请做 3 次正常的敲打动作         │                       │
│   │                                 │                       │
│   │  ✅ ✅ ⬜  已完成 2/3 次         │                       │
│   └─────────────────────────────────┘                       │
│                                                             │
│              ┌─────────────────┐                            │
│              │   完成校准      │                            │
│              └─────────────────┘                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 附录 E: 会话状态机设计

### E.1 状态定义

```typescript
// SessionState.ets
export enum SessionState {
  IDLE = 'idle',           // 空闲，未开始
  COUNTING = 'counting',   // 正在计数
  PAUSED = 'paused',       // 已暂停
  COMPLETED = 'completed'  // 已完成目标
}

export enum SessionEvent {
  START = 'start',         // 开始
  PAUSE = 'pause',         // 暂停
  RESUME = 'resume',       // 恢复
  RESET = 'reset',         // 重置
  TAP_DETECTED = 'tap',    // 检测到敲打
  TARGET_REACHED = 'target_reached' // 达到目标
}

export interface SessionData {
  state: SessionState;
  currentPart: BodyPart;
  currentCount: number;
  targetCount: number;
  startTime: number | null;
  pauseTime: number | null;
  totalPauseDuration: number;
  tapRecords: TapRecord[];
}

export interface TapRecord {
  timestamp: number;
  force: number;
  confidence: number;
  part: BodyPart;
}
```

### E.2 状态机实现

```typescript
// SessionManager.ets
export class SessionManager {
  private state: SessionState = SessionState.IDLE;
  private data: SessionData;
  private onStateChange?: (state: SessionState, data: SessionData) => void;

  constructor() {
    this.data = this.initData();
  }

  private initData(): SessionData {
    return {
      state: SessionState.IDLE,
      currentPart: BodyPart.GALLBLADDER_LEFT,
      currentCount: 0,
      targetCount: 100,
      startTime: null,
      pauseTime: null,
      totalPauseDuration: 0,
      tapRecords: []
    };
  }

  /**
   * 状态转换
   */
  transition(event: SessionEvent, payload?: any): void {
    const previousState = this.state;

    switch (this.state) {
      case SessionState.IDLE:
        if (event === SessionEvent.START) {
          this.state = SessionState.COUNTING;
          this.data.startTime = Date.now();
          this.data.currentCount = 0;
          this.data.tapRecords = [];
          this.data.totalPauseDuration = 0;
        }
        break;

      case SessionState.COUNTING:
        if (event === SessionEvent.TAP_DETECTED) {
          this.data.currentCount++;
          this.data.tapRecords.push(payload as TapRecord);
          
          if (this.data.currentCount >= this.data.targetCount) {
            this.state = SessionState.COMPLETED;
          }
        } else if (event === SessionEvent.PAUSE) {
          this.state = SessionState.PAUSED;
          this.data.pauseTime = Date.now();
        } else if (event === SessionEvent.RESET) {
          this.state = SessionState.IDLE;
          this.data = this.initData();
        }
        break;

      case SessionState.PAUSED:
        if (event === SessionEvent.RESUME) {
          this.state = SessionState.COUNTING;
          if (this.data.pauseTime) {
            this.data.totalPauseDuration += Date.now() - this.data.pauseTime;
            this.data.pauseTime = null;
          }
        } else if (event === SessionEvent.RESET) {
          this.state = SessionState.IDLE;
          this.data = this.initData();
        }
        break;

      case SessionState.COMPLETED:
        if (event === SessionEvent.RESET) {
          this.state = SessionState.IDLE;
          this.data = this.initData();
        }
        break;
    }

    this.data.state = this.state;
    
    if (this.state !== previousState && this.onStateChange) {
      this.onStateChange(this.state, this.data);
    }
  }

  /**
   * 获取会话时长（不含暂停）
   */
  getSessionDuration(): number {
    if (!this.data.startTime) return 0;
    
    const elapsed = Date.now() - this.data.startTime - this.data.totalPauseDuration;
    return Math.max(0, elapsed);
  }

  /**
   * 设置状态变更回调
   */
  setOnStateChange(callback: (state: SessionState, data: SessionData) => void): void {
    this.onStateChange = callback;
  }

  /**
   * 设置目标计数
   */
  setTarget(count: number): void {
    this.data.targetCount = Math.max(1, count);
  }

  /**
   * 切换部位
   */
  switchPart(part: BodyPart): void {
    if (this.state === SessionState.IDLE) {
      this.data.currentPart = part;
    }
  }

  getData(): SessionData {
    return { ...this.data };
  }

  getState(): SessionState {
    return this.state;
  }
}
```

### E.3 状态图

```
                    ┌────────────────────────────────────────┐
                    │                                        │
                    ▼                                        │
              ┌───────────┐                                  │
              │   IDLE    │                                  │
              │  (空闲)   │                                  │
              └───────────┘                                  │
                    │                                        │
                    │ START                                  │
                    ▼                                        │
              ┌───────────┐                                  │
         ┌───▶│ COUNTING  │◀─────────────────────┐           │
         │    │ (计数中)  │                      │           │
         │    └───────────┘                      │           │
         │          │                            │           │
         │          │ PAUSE                      │ RESUME    │
         │          ▼                            │           │
         │    ┌───────────┐                      │           │
         │    │  PAUSED   │──────────────────────┘           │
         │    │  (暂停)   │                                  │
         │    └───────────┘                                  │
         │          │                                        │
         │          │ RESET                                  │ RESET
         │          └──────────────────────────────────────▶│
         │                                                   │
         │          TAP_DETECTED                             │
         │          (count >= target)                        │
         │          ▼                                        │
         │    ┌───────────┐                                  │
         │    │ COMPLETED │──────────────────────────────────┘
         │    │  (完成)   │        RESET
         │    └───────────┘
         │
         │ RESET
         └──────────────────────────────────────────────▶ IDLE
```

---

## 附录 F: 扩展数据模型

### F.1 完整数据模型

```typescript
// models/TapDataModels.ets

/**
 * 身体部位枚举
 */
export enum BodyPart {
  GALLBLADDER_LEFT = 'gallbladder_left',   // 左胆经
  GALLBLADDER_RIGHT = 'gallbladder_right', // 右胆经
  PERICARDIUM = 'pericardium',             // 心包经
  SANJIAO = 'sanjiao',                     // 三焦经
  CUSTOM = 'custom'                        // 自定义
}

/**
 * 力度等级
 */
export enum ForceLevel {
  LIGHT = 'light',     // 轻拍 (0-33)
  MEDIUM = 'medium',   // 中等 (34-66)
  STRONG = 'strong'    // 重拍 (67-100)
}

/**
 * 单次敲打记录
 */
export interface TapRecord {
  id: string;                    // 唯一标识
  timestamp: number;             // 时间戳
  part: BodyPart;                // 部位
  force: number;                 // 力度值 (0-100)
  forceLevel: ForceLevel;        // 力度等级
  confidence: number;            // 检测置信度 (0-1)
  sessionId: string;             // 所属会话 ID
  accelerometerData?: {          // 原始加速度数据（可选）
    x: number;
    y: number;
    z: number;
  };
}

/**
 * 敲打会话
 */
export interface TapSession {
  id: string;                    // 会话 ID
  startTime: number;             // 开始时间
  endTime: number | null;        // 结束时间
  totalDuration: number;         // 总时长
  pauseDuration: number;         // 暂停时长
  part: BodyPart;                // 练习部位
  targetCount: number;           // 目标次数
  actualCount: number;           // 实际次数
  completed: boolean;            // 是否完成
  records: TapRecord[];          // 敲打记录
  statistics: SessionStatistics;// 统计数据
  calibration: CalibrationResult;// 校准信息
}

/**
 * 会话统计
 */
export interface SessionStatistics {
  averageForce: number;          // 平均力度
  averageInterval: number;       // 平均敲打间隔
  rhythmScore: number;           // 节奏评分 (0-100)
  durationMs: number;            // 实际时长
  forceDistribution: {           // 力度分布
    light: number;
    medium: number;
    strong: number;
  };
  confidence: number;            // 整体置信度
}

/**
 * 每日数据汇总
 */
export interface DailySummary {
  date: string;                  // YYYY-MM-DD
  totalSessions: number;         // 会话总数
  totalTaps: number;             // 敲打总数
  totalDuration: number;         // 总时长
  partBreakdown: Map<BodyPart, { // 分部位统计
    count: number;
    duration: number;
  }>;
  averageForce: number;          // 平均力度
  streakDays: number;            // 连续天数
  goalAchieved: boolean;         // 是否达成日目标
}

/**
 * 用户设置
 */
export interface UserSettings {
  wearingHand: 'left' | 'right'; // 佩戴手
  targetPerSession: number;      // 每次目标
  targetPerDay: number;          // 每日目标
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

### F.2 数据存储服务

```typescript
// services/DataStorageService.ets
import { preferences } from '@kit.ArkData';
import { relationalStore } from '@kit.ArkData';

export class DataStorageService {
  private static instance: DataStorageService;
  private rdbStore: relationalStore.RdbStore | null = null;
  private preferenceStore: preferences.Preferences | null = null;

  private static readonly DB_NAME = 'TapCare.db';
  private static readonly DB_VERSION = 1;

  // 表结构
  private static readonly CREATE_TAP_RECORDS_TABLE = `
    CREATE TABLE IF NOT EXISTS tap_records (
      id TEXT PRIMARY KEY,
      timestamp INTEGER NOT NULL,
      part TEXT NOT NULL,
      force INTEGER NOT NULL,
      force_level TEXT NOT NULL,
      confidence REAL NOT NULL,
      session_id TEXT NOT NULL,
      accel_x REAL,
      accel_y REAL,
      accel_z REAL
    )
  `;

  private static readonly CREATE_SESSIONS_TABLE = `
    CREATE TABLE IF NOT EXISTS sessions (
      id TEXT PRIMARY KEY,
      start_time INTEGER NOT NULL,
      end_time INTEGER,
      total_duration INTEGER NOT NULL,
      pause_duration INTEGER NOT NULL,
      part TEXT NOT NULL,
      target_count INTEGER NOT NULL,
      actual_count INTEGER NOT NULL,
      completed INTEGER NOT NULL
    )
  `;

  async initialize(context: Context): Promise<void> {
    // 初始化关系数据库
    const config: relationalStore.StoreConfig = {
      name: DataStorageService.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    this.rdbStore = await relationalStore.getRdbStore(context, config);
    
    // 创建表
    await this.rdbStore.executeSql(DataStorageService.CREATE_TAP_RECORDS_TABLE);
    await this.rdbStore.executeSql(DataStorageService.CREATE_SESSIONS_TABLE);

    // 初始化偏好设置
    this.preferenceStore = await preferences.getPreferences(
      context, 'tapcare_settings'
    );
  }

  // 保存敲打记录
  async saveTapRecord(record: TapRecord): Promise<void> {
    if (!this.rdbStore) throw new Error('Database not initialized');

    const valueBucket: relationalStore.ValuesBucket = {
      id: record.id,
      timestamp: record.timestamp,
      part: record.part,
      force: record.force,
      force_level: record.forceLevel,
      confidence: record.confidence,
      session_id: record.sessionId,
      accel_x: record.accelerometerData?.x,
      accel_y: record.accelerometerData?.y,
      accel_z: record.accelerometerData?.z
    };

    await this.rdbStore.insert('tap_records', valueBucket);
  }

  // 保存会话
  async saveSession(session: TapSession): Promise<void> {
    if (!this.rdbStore) throw new Error('Database not initialized');

    const valueBucket: relationalStore.ValuesBucket = {
      id: session.id,
      start_time: session.startTime,
      end_time: session.endTime,
      total_duration: session.totalDuration,
      pause_duration: session.pauseDuration,
      part: session.part,
      target_count: session.targetCount,
      actual_count: session.actualCount,
      completed: session.completed ? 1 : 0
    };

    await this.rdbStore.insert(
      'sessions', 
      valueBucket, 
      relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
    );
  }

  // 获取每日汇总
  async getDailySummary(date: string): Promise<DailySummary | null> {
    if (!this.rdbStore) throw new Error('Database not initialized');

    const startTime = new Date(date + 'T00:00:00').getTime();
    const endTime = new Date(date + 'T23:59:59').getTime();

    // 查询当日所有记录
    const predicates = new relationalStore.RdbPredicates('tap_records');
    predicates.between('timestamp', startTime, endTime);
    
    const cursor = await this.rdbStore.query(predicates);
    // ... 处理查询结果

    return null; // 简化实现
  }

  // 保存用户设置
  async saveSettings(settings: UserSettings): Promise<void> {
    if (!this.preferenceStore) throw new Error('Preferences not initialized');
    
    await this.preferenceStore.put('settings', JSON.stringify(settings));
    await this.preferenceStore.flush();
  }

  // 获取用户设置
  async getSettings(): Promise<UserSettings> {
    if (!this.preferenceStore) throw new Error('Preferences not initialized');
    
    const json = await this.preferenceStore.get('settings', '{}') as string;
    const settings = JSON.parse(json) as UserSettings;
    
    return settings || this.getDefaultSettings();
  }

  private getDefaultSettings(): UserSettings {
    return {
      wearingHand: 'left',
      targetPerSession: 100,
      targetPerDay: 300,
      hapticFeedback: true,
      hapticIntensity: 2,
      soundFeedback: false,
      reminder: {
        enabled: true,
        time: '20:00',
        message: '该做今天的敲打练习了！'
      },
      sensitivity: 1.0,
      calibration: null
    };
  }
}
```

---

## 附录 G: 错误处理与边界情况

### G.1 权限处理

```typescript
// services/PermissionService.ets
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

export class PermissionService {
  private static readonly REQUIRED_PERMISSIONS: Permissions[] = [
    'ohos.permission.ACCELEROMETER',
    'ohos.permission.GYROSCOPE',
    'ohos.permission.VIBRATE'
  ];

  /**
   * 检查并请求权限
   */
  static async checkAndRequestPermissions(
    context: common.UIAbilityContext
  ): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    
    for (const permission of this.REQUIRED_PERMISSIONS) {
      const grantStatus = await atManager.checkAccessToken(
        context.applicationInfo.accessTokenId,
        permission
      );

      if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        // 请求权限
        const result = await atManager.requestPermissionsFromUser(
          context,
          [permission]
        );

        if (result.authResults[0] !== 0) {
          console.error(`Permission ${permission} denied`);
          return false;
        }
      }
    }

    return true;
  }

  /**
   * 检查传感器可用性
   */
  static async checkSensorAvailability(): Promise<{
    accelerometer: boolean;
    gyroscope: boolean;
    vibrator: boolean;
  }> {
    const sensorList = sensor.getSensorListSync();
    
    return {
      accelerometer: sensorList.some(
        s => s.sensorId === sensor.SensorId.ACCELEROMETER
      ),
      gyroscope: sensorList.some(
        s => s.sensorId === sensor.SensorId.GYROSCOPE
      ),
      vibrator: true // 假设振动器可用
    };
  }
}
```

### G.2 错误处理策略

```typescript
// services/ErrorHandler.ets
export enum ErrorCode {
  SENSOR_UNAVAILABLE = 1001,
  PERMISSION_DENIED = 1002,
  CALIBRATION_REQUIRED = 1003,
  STORAGE_FULL = 1004,
  LOW_BATTERY = 1005,
  SESSION_ACTIVE = 1006
}

export interface AppError {
  code: ErrorCode;
  message: string;
  recoverable: boolean;
  action?: () => void;
}

export class ErrorHandler {
  private static errorMessages: Map<ErrorCode, string> = new Map([
    [ErrorCode.SENSOR_UNAVAILABLE, '传感器不可用，请检查设备支持'],
    [ErrorCode.PERMISSION_DENIED, '需要传感器权限才能使用敲打检测功能'],
    [ErrorCode.CALIBRATION_REQUIRED, '请先完成校准以提高检测准确率'],
    [ErrorCode.STORAGE_FULL, '存储空间不足，请清理历史数据'],
    [ErrorCode.LOW_BATTERY, '电量低于 20%，建议充电后使用'],
    [ErrorCode.SESSION_ACTIVE, '已有会话在进行中']
  ]);

  static handleError(error: AppError): void {
    console.error(`[ErrorHandler] Code: ${error.code}, Message: ${error.message}`);

    // 显示用户友好提示
    promptAction.showToast({
      message: this.errorMessages.get(error.code) || '发生未知错误',
      duration: 2000
    });

    // 可恢复错误的自动处理
    if (error.recoverable && error.action) {
      setTimeout(() => error.action?.(), 1000);
    }
  }

  static handleSensorError(error: BusinessError): AppError {
    switch (error.code) {
      case 14500101:
        return {
          code: ErrorCode.SENSOR_UNAVAILABLE,
          message: 'Sensor service exception',
          recoverable: false
        };
      case 201:
        return {
          code: ErrorCode.PERMISSION_DENIED,
          message: 'Permission denied',
          recoverable: true,
          action: () => PermissionService.checkAndRequestPermissions(
            globalThis.context
          )
        };
      default:
        return {
          code: ErrorCode.SENSOR_UNAVAILABLE,
          message: error.message,
          recoverable: false
        };
    }
  }
}
```

### G.3 边界情况处理

| 场景 | 处理策略 |
|------|----------|
| 传感器权限被拒绝 | 显示权限说明页，引导用户去设置开启 |
| 传感器不可用 | 显示"设备不支持"提示，禁用检测功能 |
| 低电量（<20%） | 显示警告，降低采样率以省电 |
| 存储空间不足 | 自动清理 30 天前的数据，提示用户导出 |
| 后台被系统杀死 | 使用 Background Tasks API 保持运行 |
| 网络断开 | 本地存储，网络恢复后同步（未来功能） |
| 手表取下 | 检测到异常加速度模式，暂停计数 |
| 剧烈运动 | 检测到持续高陀螺仪读数，暂停计数 |

```typescript
// 边界情况检测
export class EdgeCaseHandler {
  private lastWristPresence = Date.now();
  private continuousMotionCount = 0;

  /**
   * 检测手表是否被取下
   * 特征：加速度突然归零或变成固定值
   */
  detectWatchRemoval(accel: sensor.AccelerometerResponse): boolean {
    const magnitude = Math.sqrt(
      accel.x ** 2 + accel.y ** 2 + accel.z ** 2
    );
    
    // 如果加速度接近 0，可能手表已取下
    if (magnitude < 2.0) {
      return true;
    }
    
    return false;
  }

  /**
   * 检测剧烈运动
   * 特征：持续的高陀螺仪读数
   */
  detectIntenseMotion(gyro: sensor.GyroscopeResponse): boolean {
    const magnitude = Math.sqrt(
      gyro.x ** 2 + gyro.y ** 2 + gyro.z ** 2
    );
    
    if (magnitude > 5.0) {
      this.continuousMotionCount++;
      // 连续 1 秒的高运动量，判定为剧烈运动
      if (this.continuousMotionCount > 20) {
        return true;
      }
    } else {
      this.continuousMotionCount = Math.max(0, this.continuousMotionCount - 1);
    }
    
    return false;
  }

  /**
   * 低电量检测
   */
  async checkLowBattery(): Promise<boolean> {
    // 使用 batteryInfo API
    // const batteryInfo = await battery.getBatteryInfo();
    // return batteryInfo.level < 20;
    return false; // 简化实现
  }
}
```

---

## 附录 H: UI 适配方案

### H.1 多尺寸适配

```typescript
// common/DeviceAdapter.ets
import { display } from '@kit.ArkUI';

export interface DeviceConfig {
  screenWidth: number;
  screenHeight: number;
  isRound: boolean;
  scale: number;
}

export class DeviceAdapter {
  private static config: DeviceConfig | null = null;

  static async init(): Promise<void> {
    const displayInfo = display.getDefaultDisplaySync();
    const width = displayInfo.width;
    const height = displayInfo.height;
    
    // GT 4 尺寸：41mm (466x466) / 46mm (466x466)
    // 基准：466px
    const baseWidth = 466;
    
    this.config = {
      screenWidth: width,
      screenHeight: height,
      isRound: true, // GT 4 是圆形表盘
      scale: width / baseWidth
    };
  }

  static getConfig(): DeviceConfig {
    if (!this.config) {
      throw new Error('DeviceAdapter not initialized');
    }
    return this.config;
  }

  // 适配字体大小
  static scaleFont(size: number): number {
    return Math.round(size * (this.config?.scale ?? 1));
  }

  // 适配尺寸
  static scaleSize(size: number): number {
    return Math.round(size * (this.config?.scale ?? 1));
  }
}

// 使用示例
@Styles function adaptiveFont() {
  .fontSize(DeviceAdapter.scaleFont(20))
}
```

### H.2 深色模式

```typescript
// common/ThemeManager.ets
export interface Theme {
  isDark: boolean;
  colors: {
    primary: string;
    secondary: string;
    background: string;
    surface: string;
    text: string;
    textSecondary: string;
    error: string;
    success: string;
  };
}

export const LightTheme: Theme = {
  isDark: false,
  colors: {
    primary: '#FF6B6B',
    secondary: '#4ECDC4',
    background: '#FFFFFF',
    surface: '#F5F5F5',
    text: '#333333',
    textSecondary: '#666666',
    error: '#E74C3C',
    success: '#2ECC71'
  }
};

export const DarkTheme: Theme = {
  isDark: true,
  colors: {
    primary: '#FF6B6B',
    secondary: '#4ECDC4',
    background: '#1A1A1A',
    surface: '#2D2D2D',
    text: '#FFFFFF',
    textSecondary: '#AAAAAA',
    error: '#E74C3C',
    success: '#2ECC71'
  }
};

// 主题提供者
export class ThemeManager {
  private static currentTheme: Theme = DarkTheme; // 默认深色（省电）

  static getTheme(): Theme {
    return this.currentTheme;
  }

  static setTheme(isDark: boolean): void {
    this.currentTheme = isDark ? DarkTheme : LightTheme;
  }

  // 根据系统设置自动切换
  static syncWithSystem(): void {
    // 监听系统主题变化
    // const systemDark = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    // this.setTheme(systemDark);
  }
}
```

### H.3 响应式 UI 组件

```typescript
// components/AdaptiveComponents.ets
@Component
export struct AdaptiveText {
  @Prop text: string = '';
  @Prop baseFontSize: number = 16;
  @Prop fontWeight: FontWeight = FontWeight.Normal;
  @Prop fontColor: string = ThemeManager.getTheme().colors.text;

  build() {
    Text(this.text)
      .fontSize(DeviceAdapter.scaleFont(this.baseFontSize))
      .fontWeight(this.fontWeight)
      .fontColor(this.fontColor)
  }
}

@Component
export struct AdaptiveButton {
  @Prop text: string = '';
  @Prop onTap: () => void = () => {};
  @Prop buttonColor: string = ThemeManager.getTheme().colors.primary;

  build() {
    Button(this.text)
      .width(DeviceAdapter.scaleSize(120))
      .height(DeviceAdapter.scaleSize(44))
      .fontSize(DeviceAdapter.scaleFont(16))
      .backgroundColor(this.buttonColor)
      .onClick(() => this.onTap())
  }
}

// 圆形表盘专用布局
@Component
export struct RoundWatchLayout {
  @BuilderParam content: () => void;

  build() {
    Stack() {
      // 圆形背景
      Circle()
        .width('100%')
        .height('100%')
        .fill(ThemeManager.getTheme().colors.background)

      // 内容区域（留出边缘）
      Column() {
        this.content()
      }
      .width('90%')
      .height('90%')
    }
    .width('100%')
    .height('100%')
  }
}
```

---

## 总结

### 已补充的 PRD 章节

| 章节 | 内容 | 优先级 |
|------|------|--------|
| 附录 A | Windows 10 开发环境搭建指南 | 🔴 高 |
| 附录 B | 修正后的传感器 API（HarmonyOS API 12） | 🔴 高 |
| 附录 C | 敲打检测算法优化（多特征融合） | 🔴 高 |
| 附录 D | 左右手校准流程 | 🔴 高 |
| 附录 E | 会话状态机设计 | 🟡 中 |
| 附录 F | 扩展数据模型 | 🟡 中 |
| 附录 G | 错误处理与边界情况 | 🟡 中 |
| 附录 H | UI 适配（多尺寸/深色模式） | 🟡 中 |

### Win10 环境快速清单

```
✅ Windows 10 64-bit (8GB+ 内存，100GB+ 硬盘)
✅ DevEco Studio 5.0+ (一键安装，内置 JDK/Node.js/SDK)
✅ 华为开发者账号 (真机调试签名)
✅ HarmonyOS SDK API 12+ (手表开发)
```

### 下一步建议

1. **立即开始** → 按附录 A 安装 DevEco Studio
2. **创建项目骨架** → 选择 Wearable 模板
3. **实现核心算法** → 参考附录 C 的 TapDetector
4. **完成校准流程** → 参考附录 D 的 CalibrationService
5. **开发 UI 界面** → 参考附录 H 的响应式组件

---

*文档版本：V1.0.0*  
*最后更新：2026 年 2 月 24 日*
