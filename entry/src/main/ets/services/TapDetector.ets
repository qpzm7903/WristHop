/**
 * 敲敲计 (TapCare) - 敲打检测器
 * 多特征融合检测算法
 */

import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import type { TapRecord, CalibrationResult } from '../models/TapDataModels';
import { BodyPart, ForceLevel, getForceLevel, generateId } from '../models/TapDataModels';

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

export interface BaselineAccel {
  x: number;
  y: number;
  z: number;
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
  private baselineAccel: BaselineAccel = { x: 0, y: 0, z: -9.8 };

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
          } as TapEvent;
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
    } as BaselineAccel;
    console.info(`Calibrated baseline: ${JSON.stringify(this.baselineAccel)}`);
  }

  /**
   * 设置佩戴手
   */
  setWearingHand(hand: 'left' | 'right'): void {
    this.wearingHand = hand;
  }

  /**
   * 设置基线加速度
   */
  setBaselineAccel(baseline: BaselineAccel): void {
    this.baselineAccel = baseline;
  }

  /**
   * 重置检测器状态
   */
  reset(): void {
    this.isInTap = false;
    this.lastTapTime = 0;
    this.tapStartTime = 0;
    this.maxAccelDuringTap = 0;
    this.accelWindow = [];
  }
}
