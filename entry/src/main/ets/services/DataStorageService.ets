import { common } from '@kit.AbilityKit';
/**
 * 敲敲计 (TapCare) - 数据存储服务
 */

import dataPreferences from '@ohos.data.preferences';
import { CalibrationResult, UserSettings } from '../models/TapDataModels';

export class DataStorageService {
  private static instance: DataStorageService;
  private preferenceStore: dataPreferences.Preferences | null = null;
  private static readonly PREFERENCE_NAME = 'tapcare_settings';

  private constructor() {}

  static getInstance(): DataStorageService {
    if (!DataStorageService.instance) {
      DataStorageService.instance = new DataStorageService();
    }
    return DataStorageService.instance;
  }

  async initialize(context: common.UIAbilityContext): Promise<void> {
    try {
      this.preferenceStore = await dataPreferences.getPreferences(
        context, 
        DataStorageService.PREFERENCE_NAME
      );
      console.info('DataStorageService initialized');
    } catch (error) {
      console.error(`Failed to initialize DataStorageService: ${JSON.stringify(error)}`);
    }
  }

  async saveSettings(settings: UserSettings): Promise<void> {
    if (!this.preferenceStore) {
      console.error('Preferences not initialized');
      return;
    }
    
    try {
      await this.preferenceStore.put('settings', JSON.stringify(settings));
      await this.preferenceStore.flush();
      console.info('Settings saved successfully');
    } catch (error) {
      console.error(`Failed to save settings: ${JSON.stringify(error)}`);
    }
  }

  async getSettings(): Promise<UserSettings> {
    if (!this.preferenceStore) {
      return this.getDefaultSettings();
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

  async saveCalibration(calibration: CalibrationResult): Promise<void> {
    if (!this.preferenceStore) {
      console.error('Preferences not initialized');
      return;
    }
    
    try {
      await this.preferenceStore.put('calibration', JSON.stringify(calibration));
      await this.preferenceStore.flush();
      console.info('Calibration saved successfully');
    } catch (error) {
      console.error(`Failed to save calibration: ${JSON.stringify(error)}`);
    }
  }

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
