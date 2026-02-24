# AGENTS.md - WristHop (敲敲计) 开发指南

## 📱 项目概述

**HarmonyOS 5.0 / API 12** 手表应用项目，使用 **ArkTS** 开发，目标设备为 **HUAWEI GT 4** (466x466 圆形表盘)。

---

## 🛠️ 技术栈

| 项目 | 配置 |
|------|------|
| **操作系统** | HarmonyOS 5.0.0.77 |
| **API Level** | 12+ (targetSdkVersion: 21) |
| **开发语言** | ArkTS (.ets 文件) |
| **构建系统** | Hvigor 6.0.1 |
| **IDE** | DevEco Studio 5.0+ |
| **目标设备** | HUAWEI GT 4 (wearable) |

---

## 📦 项目结构

```
WristHop/
├── build-profile.json5          # 构建配置（签名、SDK 版本、构建模式）
├── code-linter.json5            # 代码检查配置
├── hvigor/                      # Hvigor 构建工具配置
├── entry/                       # 主模块
│   └── src/main/ets/
│       ├── common/              # 通用工具类
│       ├── components/          # UI 组件
│       ├── models/              # 数据模型
│       ├── pages/               # 页面
│       └── services/            # 服务层（核心逻辑）
├── oh-package.json5             # 依赖管理
└── hvigorfile.ts                # 构建脚本
```

---

## 🔧 构建命令

### 开发环境配置
1. 安装 **DevEco Studio 5.0+**
2. 配置华为开发者账号签名：
   - `File → Project Structure → Signing Configs`
   - 勾选 "Automatically generate signature"
3. 连接 GT 4 真机（USB 调试）或启动模拟器

### 构建命令
```bash
# 用 DevEco Studio 打开项目后点击运行按钮 ▶
# 或使用命令行（需配置 hvigor 环境变量）

# 清理构建
npm run clean  # 或删除 build/ 目录

# 构建 debug 版本
npm run build:debug

# 构建 release 版本
npm run build:release
```

**注意**: 模拟器不支持真实传感器数据，**必须使用真机调试**。

---

## 🧪 测试配置

### 测试框架
- **@ohos/hypium**: 1.0.24 (单元测试)
- **@ohos/hamock**: 1.0.0 (Mock 框架)

### 测试目录
- 单元测试：`entry/src/test/`
- 集成测试：`entry/src/ohosTest/`
- Mock 测试：`entry/src/mock/`

### 运行测试
```bash
# 运行所有测试
npm test

# 使用 hvigorw 运行测试
hvigorw test --module entry

# 运行单个测试文件
hvigorw test --module entry --tests "**/TapDetector.test.ets"
```

### 测试文件位置
- **单元测试**: `entry/src/test/ets/` (已覆盖：TapDetector, SessionManager, TapDataModels)
- **Mock 测试**: `entry/src/mock/`
- **集成测试**: `entry/src/ohosTest/ets/`

---

## 📝 代码风格指南

### 1. 文件命名
- **ArkTS 文件**: PascalCase (如 `TapDetector.ets`, `SessionManager.ets`)
- **测试文件**: 与被测文件同名，放在 test/ 目录

### 2. 类与接口命名
```typescript
// 类名：PascalCase
export class TapDetector { }
export class SessionManager { }

// 接口：PascalCase
interface SensorData { }
interface TapEvent { }

// 枚举：PascalCase
export enum BodyPart { }
export enum ForceLevel { }
```

### 3. 变量与函数命名
```typescript
// 变量：camelCase
private lastTapTime: number = 0;
private wearingHand: 'left' | 'right' = 'left';

// 常量：UPPER_SNAKE_CASE (static readonly)
private static readonly ACCEL_THRESHOLD = 15.0;
private static readonly WINDOW_SIZE = 20;

// 函数：camelCase
processSensorData(accel, gyro): TapEvent | null { }
calculateAccelDelta(accel): number { }
```

### 4. 文件结构
```typescript
/**
 * 文件描述注释
 * 功能说明
 */

// 1. 导入语句（按类别分组）
import { sensor } from '@kit.SensorServiceKit';
import type { TapRecord } from '../models/TapDataModels';
import { BodyPart, ForceLevel } from '../models/TapDataModels';

// 2. 接口/类型定义
interface SensorData { }

// 3. 类/枚举定义
export class ClassName { }
export enum EnumName { }
```

### 5. 注释规范
```typescript
/**
 * JSDoc 风格文档注释
 * @param paramName 参数说明
 * @returns 返回值说明
 */
public methodName(paramName: type): returnType { }

// 单行注释：使用 //
// 多行注释：使用连续 //
```

### 6. 类型系统
```typescript
// 必须显式声明类型
const count: number = 0;
const name: string = 'test';

// 函数参数和返回值必须标注类型
public process(data: SensorData): TapEvent | null { }

// 使用可选类型
accelerometerData?: { x: number; y: number; z: number; }

// 使用联合类型
private wearingHand: 'left' | 'right' = 'left';
```

### 7. 错误处理
```typescript
import { BusinessError } from '@kit.BasicServicesKit';

// 异步操作错误处理
try {
  await someAsyncOperation();
} catch (error) {
  console.error(`Operation failed: ${(error as BusinessError).message}`);
}

// 传感器订阅错误处理
sensor.on(sensor.SensorType.ACCELEROMETER, this.onAccelChange, (error: BusinessError) => {
  console.error(`Failed to subscribe accelerometer: ${error.message}`);
});
```

### 8. 单例模式（项目标准）
```typescript
export class ServiceName {
  private static instance: ServiceName;
  
  private constructor() {}
  
  public static getInstance(): ServiceName {
    if (!ServiceName.instance) {
      ServiceName.instance = new ServiceName();
    }
    return ServiceName.instance;
  }
}
```

---

## 🚨 代码检查

### Linter 配置
- **工具**: ArkTS Linter (code-linter.json5)
- **规则集**: 
  - `@performance/recommended`
  - `@typescript-eslint/recommended`
- **安全检查**: 禁止不安全的加密算法 (AES, RSA, DSA 等)

### 运行检查
```bash
# 运行代码检查
npm run lint

# 检查单个文件
npm run lint -- entry/src/main/ets/services/TapDetector.ets
```

### 忽略目录
- `**/src/ohosTest/**/*`
- `**/src/test/**/*`
- `**/build/**/*`
- `**/node_modules/**/*`

---

## 📋 开发注意事项

### 1. 真机调试
- **必须**使用 HUAWEI GT 4 真机（模拟器不支持传感器）
- 手表开启开发者模式：`设置 → 关于 → 版本号（连续点击 7 次）`
- 开启 USB 调试：`设置 → 系统和更新 → 开发者选项 → USB 调试`
- 使用原装数据线，选择「文件传输」模式

### 2. 传感器使用
```typescript
// 传感器采样率设置
sensor.setSampleRate(sensor.SensorType.ACCELEROMETER, 200000); // 20Hz
sensor.setSampleRate(sensor.SensorType.GYROSCOPE, 200000);

// 取消订阅（避免内存泄漏）
sensor.off(sensor.SensorType.ACCELEROMETER, this.onAccelChange);
```

### 3. 数据持久化
```typescript
// 使用 Preferences
import { dataPreferences } from '@kit.ArkDataStoreKit';

const pref = await dataPreferences.getPreferences(context, 'settings');
await pref.put('key', 'value');
await pref.flush();
```

### 4. UI 适配
```typescript
// 圆形表盘适配（466x466）
import { DeviceAdapter } from './common/DeviceAdapter';

const screenWidth = DeviceAdapter.getScreenWidth();
const safeArea = DeviceAdapter.getSafeArea();
```

---

## 🔍 核心算法参数

### 敲打检测阈值（TapDetector.ets）
| 参数 | 值 | 说明 |
|------|-----|------|
| `ACCEL_THRESHOLD` | 15.0 | 加速度变化阈值 (m/s²) |
| `GYRO_THRESHOLD` | 2.0 | 陀螺仪阈值 (rad/s) |
| `DEBOUNCE_MS` | 200 | 防抖时间 (ms) |
| `MIN_TAP_DURATION_MS` | 50 | 最小敲打时长 (ms) |
| `MAX_TAP_DURATION_MS` | 300 | 最大敲打时长 (ms) |
| `WINDOW_SIZE` | 20 | 传感器数据窗口大小 |

---

## 📚 参考文档

- [HarmonyOS 官方文档](https://developer.huawei.com/consumer/cn/doc/)
- [ArkTS 语言指南](https://developer.huawei.com/consumer/cn/doc/)
- [DevEco Studio 使用指南](https://developer.huawei.com/consumer/cn/doc/)
- [项目 PRD 文档](./TapCare_PRD_Supplement.md)
- [开发指南](./DEVELOPMENT_GUIDE.md)
- [GT 4 连接指南](./GT4_CONNECTION_GUIDE.md)

---

## ⚠️ 常见错误

1. **签名失败**: 确保已配置华为开发者账号
2. **传感器无数据**: 真机调试，模拟器不支持
3. **构建失败**: 清理缓存后重新构建
4. **USB 连接失败**: 使用原装数据线，选择文件传输模式

---

*最后更新：2026 年 2 月 24 日*  
*版本：V1.0.0*
