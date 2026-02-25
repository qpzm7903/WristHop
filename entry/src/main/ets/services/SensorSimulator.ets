/**
 * 传感器模拟器 - 用于模拟器测试
 */
import { sensor } from '@kit.SensorServiceKit';
import { SensorData } from './TapDetectionService';

export class SensorSimulator {
  private static isSimulating: boolean = false;
  private static simulationTimer: number = -1;
  private static accelCallback: ((data: SensorData) => void) | null = null;
  private static gyroCallback: ((data: SensorData) => void) | null = null;

  static enableSimulation(): void {
    SensorSimulator.isSimulating = true;
    console.info('Sensor simulation enabled');
  }

  static disableSimulation(): void {
    SensorSimulator.isSimulating = false;
    if (SensorSimulator.simulationTimer !== -1) {
      clearInterval(SensorSimulator.simulationTimer);
      SensorSimulator.simulationTimer = -1;
    }
    console.info('Sensor simulation disabled');
  }
  static startAccelerometerSimulation(callback: (data: SensorData) => void): void {
    SensorSimulator.accelCallback = callback;
    
    if (SensorSimulator.simulationTimer === -1) {
      SensorSimulator.simulationTimer = setInterval((): void => {
        SensorSimulator.generateSimulatedData();
      }, 50);
    }
  }
  static startGyroscopeSimulation(callback: (data: SensorData) => void): void {
    SensorSimulator.gyroCallback = callback;
  }

  static stopSimulation(): void {
    SensorSimulator.accelCallback = null;
    SensorSimulator.gyroCallback = null;
  }

  static simulateTap(): void {
    if (SensorSimulator.accelCallback) {
      const tapData: SensorData = {
        x: Math.random() * 5 - 2.5,
        y: Math.random() * 5 - 2.5,
        z: -25.0
      };
      SensorSimulator.accelCallback(tapData);
      console.info('Simulated tap detected');
    }
  }

  private static generateSimulatedData(): void {
    const now = Date.now();
    
    if (SensorSimulator.accelCallback) {
      const accelData: SensorData = {
        x: Math.sin(now / 1000) * 2 + (Math.random() - 0.5),
        y: Math.cos(now / 1000) * 2 + (Math.random() - 0.5),
        z: -9.8 + (Math.random() - 0.5)
      };
      SensorSimulator.accelCallback(accelData);
    }
    
    if (SensorSimulator.gyroCallback) {
      const gyroData: SensorData = {
        x: (Math.random() - 0.5) * 0.5,
        y: (Math.random() - 0.5) * 0.5,
        z: (Math.random() - 0.5) * 0.5
      };
      SensorSimulator.gyroCallback(gyroData);
    }
  }
}
