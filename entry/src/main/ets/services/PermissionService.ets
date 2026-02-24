/**
 * 敲敲计 (TapCare) - 权限服务
 * 管理和检查传感器权限
 */

import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { sensor } from '@kit.SensorServiceKit';

export class PermissionService {
  private static readonly REQUIRED_PERMISSIONS: string[] = [
    'ohos.permission.ACCELEROMETER',
    'ohos.permission.GYROSCOPE',
    'ohos.permission.VIBRATE'
  ];

  /**
   * 检查并请求权限
   */
  static async checkAndRequestPermissions(
    context: common.UIAbilityContext
  ): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    
    for (const permission of this.REQUIRED_PERMISSIONS) {
      try {
        const grantStatus = await atManager.checkAccessToken(
          context.applicationInfo.accessTokenId,
          permission
        );

        if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          // 请求权限
          const result = await atManager.requestPermissionsFromUser(
            context,
            [permission]
          );

          if (result.authResults[0] !== 0) {
            console.error(`Permission ${permission} denied`);
            return false;
          }
        }
        console.info(`Permission ${permission} granted`);
      } catch (error) {
        console.error(`Error checking permission ${permission}: ${JSON.stringify(error)}`);
        return false;
      }
    }

    return true;
  }

  /**
   * 检查传感器可用性
   */
  static async checkSensorAvailability(): Promise<{
    accelerometer: boolean;
    gyroscope: boolean;
  }> {
    try {
      const sensorList = sensor.getSensorListSync();
      
      return {
        accelerometer: sensorList.some(
          s => s.sensorId === sensor.SensorId.ACCELEROMETER
        ),
        gyroscope: sensorList.some(
          s => s.sensorId === sensor.SensorId.GYROSCOPE
        )
      };
    } catch (error) {
      console.error(`Error checking sensor availability: ${JSON.stringify(error)}`);
      return {
        accelerometer: false,
        gyroscope: false
      };
    }
  }

  /**
   * 检查单个权限
   */
  static async checkPermission(
    context: common.UIAbilityContext,
    permission: string
  ): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const grantStatus = await atManager.checkAccessToken(
        context.applicationInfo.accessTokenId,
        permission
      );
      return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      console.error(`Error checking permission ${permission}: ${JSON.stringify(error)}`);
      return false;
    }
  }
}
