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

  /**
   * 初始化设备配置
   */
  static async init(): Promise<void> {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      const width = displayInfo.width;
      const height = displayInfo.height;
      
      // GT 4 尺寸：466x466 圆形表盘
      // 基准：466px
      const baseWidth = 466;
      
      this.config = {
        screenWidth: width,
        screenHeight: height,
        isRound: true, // GT 4 是圆形表盘
        scale: width / baseWidth
      };
      
      console.info(`Device initialized: ${width}x${height}, scale: ${this.config.scale}`);
    } catch (error) {
      console.error(`Failed to initialize device adapter: ${JSON.stringify(error)}`);
      // 默认配置
      this.config = {
        screenWidth: 466,
        screenHeight: 466,
        isRound: true,
        scale: 1.0
      };
    }
  }

  /**
   * 获取设备配置
   */
  static getConfig(): DeviceConfig {
    if (!this.config) {
      throw new Error('DeviceAdapter not initialized. Call init() first.');
    }
    return this.config;
  }

  /**
   * 适配字体大小
   */
  static scaleFont(size: number): number {
    if (!this.config) return size;
    return Math.round(size * this.config.scale);
  }

  /**
   * 适配尺寸
   */
  static scaleSize(size: number): number {
    if (!this.config) return size;
    return Math.round(size * this.config.scale);
  }

  /**
   * 获取屏幕宽度
   */
  static getScreenWidth(): number {
    return this.config?.screenWidth || 466;
  }

  /**
   * 获取屏幕高度
   */
  static getScreenHeight(): number {
    return this.config?.screenHeight || 466;
  }

  /**
   * 检查是否为圆形表盘
   */
  static isRoundDisplay(): boolean {
    return this.config?.isRound ?? true;
  }
}
