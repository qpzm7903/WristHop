/**
 * 敲敲计 (TapCare) - 设备适配器
 * 圆形表盘适配和多尺寸支持
 */

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
    try {
      const displayInfo = display.getDefaultDisplaySync();
      const width = displayInfo.width;
      const height = displayInfo.height;
      const baseWidth = 466;
      
      DeviceAdapter.config = {
        screenWidth: width,
        screenHeight: height,
        isRound: true,
        scale: width / baseWidth
      } as DeviceConfig;
      
      console.info(`Device initialized: ${width}x${height}, scale: ${DeviceAdapter.config.scale}`);
    } catch (error) {
      console.error(`Failed to initialize device adapter: ${JSON.stringify(error)}`);
      DeviceAdapter.config = {
        screenWidth: 466,
        screenHeight: 466,
        isRound: true,
        scale: 1.0
      } as DeviceConfig;
    }
  }

  static getConfig(): DeviceConfig {
    if (!DeviceAdapter.config) {
      throw new Error('DeviceAdapter not initialized. Call init() first.');
    }
    return DeviceAdapter.config;
  }

  static scaleFont(size: number): number {
    if (!DeviceAdapter.config) return size;
    return Math.round(size * DeviceAdapter.config.scale);
  }

  static scaleSize(size: number): number {
    if (!DeviceAdapter.config) return size;
    return Math.round(size * DeviceAdapter.config.scale);
  }

  static getScreenWidth(): number {
    return DeviceAdapter.config?.screenWidth || 466;
  }

  static getScreenHeight(): number {
    return DeviceAdapter.config?.screenHeight || 466;
  }

  static isRoundDisplay(): boolean {
    return DeviceAdapter.config?.isRound ?? true;
  }
}
