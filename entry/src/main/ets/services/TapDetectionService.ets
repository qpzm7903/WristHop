/**
 * 敲敲计 (TapCare) - 敲打检测服务
 * 管理传感器订阅和敲打事件回调
 */

import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TapDetector } from './TapDetector';
import type { TapRecord, BodyPart, CalibrationResult } from '../models/TapDataModels';
import { ForceLevel, getForceLevel, generateId } from '../models/TapDataModels';

export type TapCallback = (tapRecord: TapRecord) => void;

export class TapDetectionService {
  private static instance: TapDetectionService;
  private detector: TapDetector = new TapDetector();
  private isSubscribed: boolean = false;
  private isGyroSubscribed: boolean = false;
  private currentPart: BodyPart = BodyPart.GALLBLADDER_LEFT;
  private currentSessionId: string = '';
  private onTapCallback: TapCallback | null = null;

  private constructor() {}

  static getInstance(): TapDetectionService {
    if (!TapDetectionService.instance) {
      TapDetectionService.instance = new TapDetectionService();
    }
    return TapDetectionService.instance;
  }

  /**
   * 启动加速度传感器订阅
   */
  startDetection(): void {
    if (this.isSubscribed) return;
    
    try {
      // interval 单位：纳秒，50000000ns = 50ms = 20Hz（推荐省电模式）
      sensor.on(
        sensor.SensorId.ACCELEROMETER, 
        (data: sensor.AccelerometerResponse) => {
          this.processAccelerometer(data);
        }, 
        { interval: 50000000 } // 50ms 间隔
      );
      this.isSubscribed = true;
      console.info('Accelerometer subscribed successfully');
    } catch (error) {
      const e: BusinessError = error as BusinessError;
      console.error(`Failed to subscribe accelerometer: Code ${e.code}, ${e.message}`);
    }
  }

  /**
   * 启动陀螺仪传感器订阅（辅助判断）
   */
  startGyroscope(): void {
    if (this.isGyroSubscribed) return;
    
    try {
      sensor.on(
        sensor.SensorId.GYROSCOPE, 
        (data: sensor.GyroscopeResponse) => {
          this.processGyroscope(data);
        }, 
        { interval: 50000000 }
      );
      this.isGyroSubscribed = true;
      console.info('Gyroscope subscribed successfully');
    } catch (error) {
      const e: BusinessError = error as BusinessError;
      console.error(`Failed to subscribe gyroscope: Code ${e.code}, ${e.message}`);
    }
  }

  /**
   * 停止所有传感器订阅
   */
  stopDetection(): void {
    if (!this.isSubscribed && !this.isGyroSubscribed) return;
    
    try {
      if (this.isSubscribed) {
        sensor.off(sensor.SensorId.ACCELEROMETER);
        this.isSubscribed = false;
        console.info('Accelerometer unsubscribed');
      }
      if (this.isGyroSubscribed) {
        sensor.off(sensor.SensorId.GYROSCOPE);
        this.isGyroSubscribed = false;
        console.info('Gyroscope unsubscribed');
      }
    } catch (error) {
      const e: BusinessError = error as BusinessError;
      console.error(`Failed to unsubscribe: Code ${e.code}, ${e.message}`);
    }
  }

  /**
   * 设置敲打回调
   */
  setOnTapCallback(callback: TapCallback): void {
    this.onTapCallback = callback;
  }

  /**
   * 设置当前敲打部位
   */
  setCurrentPart(part: BodyPart): void {
    this.currentPart = part;
  }

  /**
   * 设置当前会话 ID
   */
  setSessionId(sessionId: string): void {
    this.currentSessionId = sessionId;
  }

  /**
   * 校准基准加速度
   */
  calibrate(baselineAccel: { x: number, y: number, z: number }): void {
    this.detector.setBaselineAccel(baselineAccel);
  }

  /**
   * 设置佩戴手
   */
  setWearingHand(hand: 'left' | 'right'): void {
    this.detector.setWearingHand(hand);
  }

  /**
   * 重置检测器
   */
  reset(): void {
    this.detector.reset();
  }

  /**
   * 检查是否正在检测
   */
  isDetecting(): boolean {
    return this.isSubscribed;
  }

  /**
   * 处理加速度数据
   */
  private processAccelerometer(data: sensor.AccelerometerResponse): void {
    // 如果没有陀螺仪数据，使用简化处理
    const dummyGyro: sensor.GyroscopeResponse = {
      x: 0,
      y: 0,
      z: 0
    } as sensor.GyroscopeResponse;

    const tapEvent = this.detector.processSensorData(data, dummyGyro);
    
    if (tapEvent && this.onTapCallback) {
      const tapRecord: TapRecord = {
        id: generateId(),
        timestamp: tapEvent.timestamp,
        part: this.currentPart,
        force: tapEvent.force,
        forceLevel: getForceLevel(tapEvent.force),
        confidence: tapEvent.confidence,
        sessionId: this.currentSessionId,
        accelerometerData: {
          x: data.x,
          y: data.y,
          z: data.z
        }
      };
      
      this.onTapCallback(tapRecord);
    }
  }

  /**
   * 处理陀螺仪数据
   */
  private processGyroscope(data: sensor.GyroscopeResponse): void {
    // 陀螺仪数据主要用于辅助判断，具体逻辑在 TapDetector 中
    // 这里可以添加额外的陀螺仪数据处理
  }
}
