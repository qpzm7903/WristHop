/**
 * 敲敲计 (TapCare) - 权限服务
 */

import { abilityAccessCtrl, common } from '@kit.AbilityKit';

interface SensorAvailability {
  accelerometer: boolean;
  gyroscope: boolean;
}

export class PermissionService {
  private static readonly REQUIRED_PERMISSIONS: string[] = [
    'ohos.permission.ACCELEROMETER',
    'ohos.permission.GYROSCOPE',
    'ohos.permission.VIBRATE'
  ];

  static async checkAndRequestPermissions(
    context: common.UIAbilityContext
  ): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    
    try {
      const grantStatus = atManager.checkAccessTokenSync(
        context.applicationInfo.accessTokenId,
        'ohos.permission.ACCELEROMETER'
      );
      
      if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.warn('Accelerometer permission not granted');
        return false;
      }
      
      console.info('Permissions granted');
      return true;
    } catch (error) {
      console.error(`Error checking permissions: ${JSON.stringify(error)}`);
      return false;
    }
  }

  static async checkSensorAvailability(): Promise<SensorAvailability> {
    return {
      accelerometer: true,
      gyroscope: true
    } as SensorAvailability;
  }

  static async checkPermission(
    context: common.UIAbilityContext
  ): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const grantStatus = atManager.checkAccessTokenSync(
        context.applicationInfo.accessTokenId,
        'ohos.permission.ACCELEROMETER'
      );
      return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      console.error(`Error checking permission: ${JSON.stringify(error)}`);
      return false;
    }
  }
}
