/**
 * 敲敲计 (TapCare) - 数据存储服务
 * 使用 Preferences 存储用户设置和会话数据
 */

import { preferences } from '@kit.ArkData';
import type { UserSettings, TapSession, CalibrationResult } from '../models/TapDataModels';
import { BodyPart } from '../models/TapDataModels';

export class DataStorageService {
  private static instance: DataStorageService;
  private preferenceStore: preferences.Preferences | null = null;
  private static readonly PREFERENCE_NAME = 'tapcare_settings';

  private constructor() {}

  static getInstance(): DataStorageService {
    if (!DataStorageService.instance) {
      DataStorageService.instance = new DataStorageService();
    }
    return DataStorageService.instance;
  }

  /**
   * 初始化存储
   */
  async initialize(context: any): Promise<void> {
    try {
      this.preferenceStore = await preferences.getPreferences(
        context, 
        DataStorageService.PREFERENCE_NAME
      );
      console.info('DataStorageService initialized');
    } catch (error) {
      console.error(`Failed to initialize DataStorageService: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 保存用户设置
   */
  async saveSettings(settings: UserSettings): Promise<void> {
    if (!this.preferenceStore) {
      throw new Error('Preferences not initialized');
    }
    
    try {
      await this.preferenceStore.put('settings', JSON.stringify(settings));
      await this.preferenceStore.flush();
      console.info('Settings saved successfully');
    } catch (error) {
      console.error(`Failed to save settings: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 获取用户设置
   */
  async getSettings(): Promise<UserSettings> {
    if (!this.preferenceStore) {
      throw new Error('Preferences not initialized');
    }
    
    try {
      const json = await this.preferenceStore.get('settings', '') as string;
      
      if (!json) {
        return this.getDefaultSettings();
      }
      
      const settings = JSON.parse(json) as UserSettings;
      return settings || this.getDefaultSettings();
    } catch (error) {
      console.error(`Failed to get settings: ${JSON.stringify(error)}`);
      return this.getDefaultSettings();
    }
  }

  /**
   * 保存校准结果
   */
  async saveCalibration(calibration: CalibrationResult): Promise<void> {
    if (!this.preferenceStore) {
      throw new Error('Preferences not initialized');
    }
    
    try {
      await this.preferenceStore.put('calibration', JSON.stringify(calibration));
      await this.preferenceStore.flush();
      console.info('Calibration saved successfully');
    } catch (error) {
      console.error(`Failed to save calibration: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 获取校准结果
   */
  async getCalibration(): Promise<CalibrationResult | null> {
    if (!this.preferenceStore) {
      return null;
    }
    
    try {
      const json = await this.preferenceStore.get('calibration', '') as string;
      
      if (!json) {
        return null;
      }
      
      return JSON.parse(json) as CalibrationResult;
    } catch (error) {
      console.error(`Failed to get calibration: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 保存会话记录（简化版，仅保存最近一次）
   */
  async saveSession(session: TapSession): Promise<void> {
    if (!this.preferenceStore) {
      throw new Error('Preferences not initialized');
    }
    
    try {
      const key = `session_${session.id}`;
      await this.preferenceStore.put(key, JSON.stringify(session));
      
      // 更新会话列表
      const sessionIds = await this.getSessionIds();
      sessionIds.push(session.id);
      await this.preferenceStore.put('session_ids', JSON.stringify(sessionIds));
      
      await this.preferenceStore.flush();
      console.info(`Session ${session.id} saved successfully`);
    } catch (error) {
      console.error(`Failed to save session: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 获取会话 ID 列表
   */
  private async getSessionIds(): Promise<string[]> {
    if (!this.preferenceStore) {
      return [];
    }
    
    const json = await this.preferenceStore.get('session_ids', '[]') as string;
    return JSON.parse(json) as string[];
  }

  /**
   * 获取默认设置
   */
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
