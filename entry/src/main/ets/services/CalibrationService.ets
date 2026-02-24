/**
 * 敲敲计 (TapCare) - 校准服务
 * 左右手校准和基准加速度校准
 */

import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import type { CalibrationResult } from '../models/TapDataModels';

export class CalibrationService {
  private static instance: CalibrationService;
  private samples: Array<{
    accel: sensor.AccelerometerResponse;
    gyro: sensor.GyroscopeResponse;
  }> = [];
  
  private static readonly SAMPLE_COUNT = 50; // 采样次数
  private static readonly SAMPLE_INTERVAL = 50000000; // 50ms

  private constructor() {}

  static getInstance(): CalibrationService {
    if (!CalibrationService.instance) {
      CalibrationService.instance = new CalibrationService();
    }
    return CalibrationService.instance;
  }

  /**
   * 开始校准流程 - 静止校准
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
        sensor.on(
          sensor.SensorId.ACCELEROMETER, 
          callback, 
          { interval: CalibrationService.SAMPLE_INTERVAL }
        );
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
          console.info(`Detected wearing hand: ${hand}, avgX: ${avgX}, avgY: ${avgY}`);
          resolve(hand);
        }
      };

      try {
        sensor.on(
          sensor.SensorId.GYROSCOPE, 
          callback, 
          { interval: CalibrationService.SAMPLE_INTERVAL }
        );
      } catch (error) {
        // 默认左手
        console.warn('Gyroscope detection failed, defaulting to left hand');
        resolve('left');
      }
    });
  }

  /**
   * 处理校准数据
   */
  private processCalibrationData(): CalibrationResult {
    // 计算加速度平均值作为基线
    const avgAccel = {
      x: this.samples.reduce((sum, s) => sum + s.accel.x, 0) / this.samples.length,
      y: this.samples.reduce((sum, s) => sum + s.accel.y, 0) / this.samples.length,
      z: this.samples.reduce((sum, s) => sum + s.accel.z, 0) / this.samples.length
    };

    // 根据 z 轴方向判断佩戴手（简化判断）
    // 左手佩戴时，z 轴通常朝下为负；右手佩戴时相反
    const wearingHand = avgAccel.z < 0 ? 'left' : 'right';

    const result: CalibrationResult = {
      wearingHand,
      baselineAccel: avgAccel,
      baselineGyro: { x: 0, y: 0, z: 0 },
      sensitivity: 1.0, // 默认灵敏度
      calibratedAt: Date.now()
    };

    console.info(`Calibration result: ${JSON.stringify(result)}`);
    return result;
  }

  /**
   * 获取校准进度（采样百分比）
   */
  getCalibrationProgress(): number {
    return Math.min(100, Math.round((this.samples.length / CalibrationService.SAMPLE_COUNT) * 100));
  }

  /**
   * 重置采样数据
   */
  resetSamples(): void {
    this.samples = [];
  }
}
