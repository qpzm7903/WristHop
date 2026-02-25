/**
 * 敲敲计 (TapCare) - 校准服务
 */

import { sensor } from '@kit.SensorServiceKit';
import { CalibrationResult, BaselineData } from '../models/TapDataModels';

interface CalibrationSample {
  accel: sensor.AccelerometerResponse;
  gyro: sensor.GyroscopeResponse;
}

export class CalibrationService {
  private static instance: CalibrationService;
  private samples: Array<CalibrationSample> = [];
  
  private static readonly SAMPLE_COUNT = 50;
  private static readonly SAMPLE_INTERVAL = 50000000;

  private constructor() {}

  static getInstance(): CalibrationService {
    if (!CalibrationService.instance) {
      CalibrationService.instance = new CalibrationService();
    }
    return CalibrationService.instance;
  }

  async startCalibration(): Promise<CalibrationResult> {
    return new Promise((resolve, reject) => {
      this.samples = [];
      
      console.info('请保持手臂自然下垂，静止站立...');
      
      const callback = (accel: sensor.AccelerometerResponse) => {
        this.samples.push({ 
          accel, 
          gyro: { x: 0, y: 0, z: 0 } as sensor.GyroscopeResponse 
        } as CalibrationSample);
        
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

  async detectWearingHand(): Promise<'left' | 'right'> {
    return new Promise((resolve) => {
      const gyroSamples: sensor.GyroscopeResponse[] = [];
      
      console.info('请抬起手腕看表，然后放下，重复 3 次...');
      
      const callback = (gyro: sensor.GyroscopeResponse) => {
        gyroSamples.push(gyro);
        
        if (gyroSamples.length >= 60) {
          sensor.off(sensor.SensorId.GYROSCOPE);
          
          const avgX = gyroSamples.reduce(
            (sum, g) => sum + g.x, 0
          ) / gyroSamples.length;
          
          const hand = avgX > 0 ? 'left' : 'right';
          console.info(`Detected wearing hand: ${hand}, avgX: ${avgX}`);
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
        console.warn('Gyroscope detection failed, defaulting to left hand');
        resolve('left');
      }
    });
  }

  private processCalibrationData(): CalibrationResult {
    const x = this.samples.reduce((sum, s) => sum + s.accel.x, 0) / this.samples.length;
    const y = this.samples.reduce((sum, s) => sum + s.accel.y, 0) / this.samples.length;
    const z = this.samples.reduce((sum, s) => sum + s.accel.z, 0) / this.samples.length;
    
    const avgAccel: BaselineData = {
      x,
      y,
      z
    };

    const wearingHand: 'left' | 'right' = z < 0 ? 'left' : 'right';

    const result: CalibrationResult = {
      wearingHand,
      baselineAccel: avgAccel,
      baselineGyro: { x: 0, y: 0, z: 0 },
      sensitivity: 1.0,
      calibratedAt: Date.now()
    };

    console.info(`Calibration result: ${JSON.stringify(result)}`);
    return result;
  }

  getCalibrationProgress(): number {
    return Math.min(100, Math.round((this.samples.length / CalibrationService.SAMPLE_COUNT) * 100));
  }

  resetSamples(): void {
    this.samples = [];
  }
}
