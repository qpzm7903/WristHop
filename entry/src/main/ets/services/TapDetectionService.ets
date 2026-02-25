/**
 * 敲敲计 (TapCare) - 敲打检测服务
 */
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TapDetector } from './TapDetector';
import { TapRecord, BodyPart, CalibrationResult, BaselineData } from '../models/TapDataModels';
import { ForceLevel, getForceLevel, generateId } from '../models/TapDataModels';
import { SensorSimulator } from './SensorSimulator';
import type { BaselineAccel } from './TapDetector';

export interface SensorData {
  x: number;
  y: number;
  z: number;
}

export type TapCallback = (tapRecord: TapRecord) => void;

export class TapDetectionService {
  private static instance: TapDetectionService;
  private detector: TapDetector = new TapDetector();
  private isSubscribed: boolean = false;
  private isGyroSubscribed: boolean = false;
  private currentPart: BodyPart = BodyPart.GALLBLADDER_LEFT;
  private currentSessionId: string = '';
  private onTapCallback: TapCallback | null = null;
  private isSimulationMode: boolean = false;

  private constructor() {}

  static getInstance(): TapDetectionService {
    if (!TapDetectionService.instance) {
      TapDetectionService.instance = new TapDetectionService();
    }
    return TapDetectionService.instance;
  }

  setSimulationMode(enabled: boolean): void {
    this.isSimulationMode = enabled;
    if (enabled) {
      SensorSimulator.enableSimulation();
    } else {
      SensorSimulator.disableSimulation();
    }
  }

  startDetection(): void {
    if (this.isSubscribed) return;
    
    try {
      if (this.isSimulationMode) {
        SensorSimulator.startAccelerometerSimulation((data: SensorData) => {
          this.processAccelerometer(data);
        });
      } else {
        sensor.on(
          sensor.SensorId.ACCELEROMETER, 
          (data: sensor.AccelerometerResponse) => {
            const sensorData: SensorData = { x: data.x, y: data.y, z: data.z };
            this.processAccelerometer(sensorData);
          }, 
          { interval: 50000000 }
        );
      }
      this.isSubscribed = true;
      console.info('Accelerometer subscribed successfully');
    } catch (error) {
      console.warn('Falling back to simulation mode');
      this.setSimulationMode(true);
      this.startDetection();
    }
  }

  startGyroscope(): void {
    if (this.isGyroSubscribed) return;
    
    try {
      if (this.isSimulationMode) {
        SensorSimulator.startGyroscopeSimulation((data: SensorData) => {
          this.processGyroscope(data);
        });
      } else {
        sensor.on(
          sensor.SensorId.GYROSCOPE, 
          (data: sensor.GyroscopeResponse) => {
            const gyroData: SensorData = { x: data.x, y: data.y, z: data.z };
            this.processGyroscope(gyroData);
          }, 
          { interval: 50000000 }
        );
      }
      this.isGyroSubscribed = true;
      console.info('Gyroscope subscribed successfully');
    } catch (error) {
      console.error(`Failed to subscribe gyroscope: ${JSON.stringify(error)}`);
    }
  }

  stopDetection(): void {
    if (!this.isSubscribed && !this.isGyroSubscribed) return;
    
    SensorSimulator.stopSimulation();
    if (!this.isSimulationMode) {
      try {
        if (this.isSubscribed) {
          sensor.off(sensor.SensorId.ACCELEROMETER);
          this.isSubscribed = false;
        }
        if (this.isGyroSubscribed) {
          sensor.off(sensor.SensorId.GYROSCOPE);
          this.isGyroSubscribed = false;
        }
      } catch (error) {
        console.error(`Failed to unsubscribe: ${JSON.stringify(error)}`);
      }
    } else {
      this.isSubscribed = false;
      this.isGyroSubscribed = false;
    }
    console.info('Detection stopped');
  }

  simulateTap(): void {
    if (this.isSimulationMode) {
      SensorSimulator.simulateTap();
      console.info('Tap simulation triggered');
    }
  }

  setOnTapCallback(callback: TapCallback): void {
    this.onTapCallback = callback;
  }

  setCurrentPart(part: BodyPart): void {
    this.currentPart = part;
  }

  setSessionId(sessionId: string): void {
    this.currentSessionId = sessionId;
  }
  calibrate(baselineAccel: BaselineAccel): void {
    this.detector.setBaselineAccel(baselineAccel);
  }

  setWearingHand(hand: 'left' | 'right'): void {
    this.detector.setWearingHand(hand);
  }

  reset(): void {
    this.detector.reset();
  }

  isDetecting(): boolean {
    return this.isSubscribed;
  }
  private processAccelerometer(data: SensorData): void {
    const dummyGyro: SensorData = { x: 0, y: 0, z: 0 };
    const accelerometerData: sensor.AccelerometerResponse = { x: data.x, y: data.y, z: data.z, timestamp: 0, accuracy: 0 } as sensor.AccelerometerResponse;
    const gyroscopeData: sensor.GyroscopeResponse = { x: dummyGyro.x, y: dummyGyro.y, z: dummyGyro.z, timestamp: 0, accuracy: 0 } as sensor.GyroscopeResponse;
    const tapEvent = this.detector.processSensorData(accelerometerData, gyroscopeData);
    
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

  private processGyroscope(data: SensorData): void {
    console.debug(`Gyro data: ${data.x}, ${data.y}, ${data.z}`);
  }
}
