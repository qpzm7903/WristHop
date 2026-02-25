/**
 * 敲敲计 (TapCare) - 主界面
 * 敲打计数和会话管理
 */

import { SessionManager } from '../services/SessionManager';
import { TapDetectionService } from '../services/TapDetectionService';
import { DataStorageService } from '../services/DataStorageService';
import { PermissionService } from '../services/PermissionService';
import { CalibrationService } from '../services/CalibrationService';
import { DeviceAdapter } from '../common/DeviceAdapter';
import { ThemeManager } from '../common/ThemeManager';
import { SessionState, TapRecord, BodyPart } from '../models/TapDataModels';
import { SessionEvent, generateId, getForceLevel } from '../models/TapDataModels';
import { SensorSimulator } from '../services/SensorSimulator';
import { vibrator } from '@kit.SensorServiceKit';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import type { BaselineAccel } from '../services/TapDetector';

@Entry
@Component
struct Index {
  // 状态
  @State currentState: string = 'idle';
  @State currentCount: number = 0;
  @State targetCount: number = 100;
  @State sessionDuration: string = '0:00';
  @State selectedPart: string = 'gallbladder_left';
  @State isCalibrated: boolean = false;
  
  // 服务实例
  private sessionManager: SessionManager = SessionManager.getInstance();
  private tapDetectionService: TapDetectionService = TapDetectionService.getInstance();
  private dataStorageService: DataStorageService = DataStorageService.getInstance();
  private calibrationService: CalibrationService = CalibrationService.getInstance();
  
  // 计时器
  private durationTimer: number = -1;
  private context: common.UIAbilityContext | null = null;

  aboutToAppear() {
    // 启用模拟器模式
    this.tapDetectionService.setSimulationMode(false);
    console.info('Real sensor mode enabled (simulation disabled)');
    // 初始化设备适配器
    DeviceAdapter.init().then(() => {
      console.info('Device adapter initialized');
    });
    
    // 获取上下文
    try {
      this.context = getContext(this) as common.UIAbilityContext;
      
      // 检查权限
      this.checkPermissions();
      
      // 加载设置
      this.loadSettings();
      
      // 设置状态回调
      this.setupSessionCallbacks();
      
      // 设置敲打回调
      this.setupTapCallback();
    } catch (error) {
      console.error(`Failed to initialize: ${JSON.stringify(error)}`);
    }
  }

  aboutToDisappear() {
    // 停止检测
    this.stopSession();
    
    // 清除计时器
    if (this.durationTimer !== -1) {
      clearInterval(this.durationTimer);
    }
  }

  /**
   * 检查权限
   */
  private async checkPermissions() {
    if (!this.context) return;
    
    try {
      const hasPermission = await PermissionService.checkAndRequestPermissions(this.context);
      if (!hasPermission) {
        promptAction.showToast({
          message: '需要传感器权限才能使用敲打检测功能',
          duration: 3000
        });
      }
    } catch (error) {
      console.error(`Permission check failed: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 加载用户设置
   */
  private async loadSettings() {
    try {
      if (this.context) { await this.dataStorageService.initialize(this.context); }
      const settings = await this.dataStorageService.getSettings();
      
      this.targetCount = settings.targetPerSession;
      this.sessionManager.setTarget(this.targetCount);
      
      // 检查是否已校准
      const calibration = await this.dataStorageService.getCalibration();
      if (calibration) {
        this.isCalibrated = true;
        this.tapDetectionService.calibrate(calibration.baselineAccel as BaselineAccel);
        this.tapDetectionService.setWearingHand(calibration.wearingHand);
      }
    } catch (error) {
      console.error(`Failed to load settings: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 设置会话回调
   */
  private setupSessionCallbacks() {
    this.sessionManager.setOnStateChange((state: SessionState, data) => {
      this.currentState = state;
      this.currentCount = data.currentCount;
      
      // 状态变化时更新 UI
      if (state === SessionState.COMPLETED) {
        this.onSessionCompleted();
      }
    });
  }

  /**
   * 设置敲打回调
   */
  private setupTapCallback() {
    this.tapDetectionService.setOnTapCallback((tapRecord: TapRecord) => {
      // 振动反馈
      this.provideHapticFeedback();
      
      // 通知会话管理器
      this.sessionManager.onTapDetected(tapRecord);
      
      // 更新 UI
      this.currentCount = this.sessionManager.getCurrentCount();
    });
  }

  /**
   * 提供振动反馈
   */
  private provideHapticFeedback() {
    try {
      vibrator.vibrate(50); // 振动 50ms
    } catch (error) {
      console.error(`Vibration failed: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 会话完成
   */
  private onSessionCompleted() {
    // 停止计时
    if (this.durationTimer !== -1) {
      clearInterval(this.durationTimer);
      this.durationTimer = -1;
    }
    
    // 振动庆祝
    try {
      vibrator.vibrate(100);
    } catch (error) {
      // ignore
    }
    
    promptAction.showToast({
      message: `恭喜！完成 ${this.targetCount} 次敲打`,
      duration: 3000
    });
  }

  /**
   * 开始会话
   */
  private startSession() {
    if (!this.isCalibrated) {
      promptAction.showToast({
        message: '请先完成校准',
        duration: 2000
      });
      return;
    }
    
    // 生成会话 ID
    const sessionId = generateId();
    this.tapDetectionService.setSessionId(sessionId);
    
    // 设置当前部位
    const partMap: Record<string, BodyPart> = {
      'gallbladder_left': BodyPart.GALLBLADDER_LEFT,
      'gallbladder_right': BodyPart.GALLBLADDER_RIGHT,
      'pericardium': BodyPart.PERICARDIUM,
      'sanjiao': BodyPart.SANJIAO
    };
    this.tapDetectionService.setCurrentPart(partMap[this.selectedPart]);
    
    // 启动传感器
    this.tapDetectionService.startDetection();
    
    // 启动会话
    this.sessionManager.transition(SessionEvent.START);
    
    // 启动计时器
    this.startDurationTimer();
    
    promptAction.showToast({
      message: '开始计数，请开始敲打',
      duration: 1500
    });
  }

  /**
   * 停止会话
   */
  private stopSession() {
    this.tapDetectionService.stopDetection();
    this.sessionManager.reset();
    this.currentCount = 0;
    this.sessionDuration = '0:00';
    
    if (this.durationTimer !== -1) {
      clearInterval(this.durationTimer);
      this.durationTimer = -1;
    }
  }

  /**
   * 暂停/恢复会话
   */
  private togglePause() {
    if (this.currentState === 'counting') {
      this.sessionManager.transition(SessionEvent.PAUSE);
    } else if (this.currentState === 'paused') {
      this.sessionManager.transition(SessionEvent.RESUME);
    }
  }

  /**
   * 启动计时器
   */
  private startDurationTimer() {
    this.durationTimer = setInterval(() => {
      this.sessionDuration = this.sessionManager.getFormattedDuration();
    }, 1000) as number;
  }

  /**
   * 开始校准
   */
  private async startCalibration() {
    promptAction.showToast({
      message: '请保持手臂自然下垂，静止站立 3 秒...',
      duration: 3000
    });
    
    try {
      const result = await this.calibrationService.startCalibration();
      
      // 保存校准结果
      await this.dataStorageService.saveCalibration(result);
      
      // 应用到检测服务
      this.tapDetectionService.calibrate(result.baselineAccel as BaselineAccel);
      this.tapDetectionService.setWearingHand(result.wearingHand);
      
      this.isCalibrated = true;
      
      promptAction.showToast({
        message: `校准完成！佩戴手：${result.wearingHand === 'left' ? '左手' : '右手'}`,
        duration: 2000
      });
    } catch (error) {
      promptAction.showToast({
        message: '校准失败，请重试',
        duration: 2000
      });
      console.error(`Calibration failed: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 部位标签
   */
  private getPartLabel(partId: string): string {
    const labels: Record<string, string> = {
      'gallbladder_left': '左胆经',
      'gallbladder_right': '右胆经',
      'pericardium': '心包经',
      'sanjiao': '三焦经'
    };
    return labels[partId] || '';
  }

  build() {
    Stack() {
      // 圆形背景
      Circle()
        .width('100%')
        .height('100%')
        .fill(ThemeManager.getTheme().colors.background)

      // 主内容
      Column() {
        // 顶部：状态指示器
        Row() {
          Text(this.currentState === 'idle' ? '准备' : 
               this.currentState === 'counting' ? '计数中' :
               this.currentState === 'paused' ? '已暂停' : '已完成')
            .fontSize(DeviceAdapter.scaleFont(12))
            .fontColor(ThemeManager.getTheme().colors.textSecondary)
          
          Text(this.sessionDuration)
            .fontSize(DeviceAdapter.scaleFont(12))
            .fontColor(ThemeManager.getTheme().colors.textSecondary)
            .margin({ left: 8 })
        }
        .margin({ top: 20, bottom: 20 })

        // 中间：计数显示
        Column() {
          // 当前计数
          Text(this.currentCount.toString())
            .fontSize(DeviceAdapter.scaleFont(48))
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeManager.getTheme().colors.primary)
          
          Text(`/ ${this.targetCount}`)
            .fontSize(DeviceAdapter.scaleFont(20))
            .fontColor(ThemeManager.getTheme().colors.textSecondary)
            .margin({ top: 4 })

          // 进度条
          Progress({ value: this.currentCount, total: this.targetCount })
            .width(DeviceAdapter.scaleSize(200))
            .height(DeviceAdapter.scaleSize(8))
            .color(ThemeManager.getTheme().colors.primary)
            .margin({ top: 16 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 40 })

        // 部位选择
        Column() {
          Text('选择部位')
            .fontSize(DeviceAdapter.scaleFont(12))
            .fontColor(ThemeManager.getTheme().colors.textSecondary)
            .margin({ bottom: 8 })
          
          Row() {
            ForEach(['gallbladder_left', 'gallbladder_right', 'pericardium', 'sanjiao'], (partId: string) => {
              Text(this.getPartLabel(partId))
                .fontSize(DeviceAdapter.scaleFont(11))
                .fontColor(this.selectedPart === partId ? 
                  ThemeManager.getTheme().colors.primary : 
                  ThemeManager.getTheme().colors.textSecondary)
                .padding({ left: 6, right: 6, top: 3, bottom: 3 })
                .backgroundColor(this.selectedPart === partId ? 
                  ThemeManager.getTheme().colors.surface : 'transparent')
                .borderRadius(DeviceAdapter.scaleSize(6))
                .onClick(() => {
                  if (this.currentState === 'idle') {
                    this.selectedPart = partId;
                  }
                })
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceEvenly)
        }
        .margin({ top: 30 })

        // 底部：控制按钮
        // 模拟器测试按钮
        Column() {
          Button('模拟敲打')
            .width(DeviceAdapter.scaleSize(100))
            .height(DeviceAdapter.scaleSize(32))
            .fontSize(DeviceAdapter.scaleFont(11))
            .fontColor('#FFFFFF')
            .backgroundColor('#FF9800')
            .onClick(() => {
              this.tapDetectionService.simulateTap();
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 10 })

        // 底部：控制按钮
        Row() {
          if (this.currentState === 'idle' || this.currentState === 'completed') {
            Button('开始')
              .width(DeviceAdapter.scaleSize(100))
              .height(DeviceAdapter.scaleSize(40))
              .fontSize(DeviceAdapter.scaleFont(14))
              .fontColor('#FFFFFF')
              .backgroundColor(ThemeManager.getTheme().colors.primary)
              .onClick(() => this.startSession())
          } else {
            Button(this.currentState === 'counting' ? '暂停' : '继续')
              .width(DeviceAdapter.scaleSize(80))
              .height(DeviceAdapter.scaleSize(40))
              .fontSize(DeviceAdapter.scaleFont(14))
              .fontColor('#FFFFFF')
              .backgroundColor(this.currentState === 'counting' ? '#F39C12' : '#3498DB')
              .onClick(() => this.togglePause())
            
            Button('结束')
              .width(DeviceAdapter.scaleSize(80))
              .height(DeviceAdapter.scaleSize(40))
              .fontSize(DeviceAdapter.scaleFont(14))
              .fontColor('#FFFFFF')
              .backgroundColor('#E74C3C')
              .margin({ left: 12 })
              .onClick(() => this.stopSession())
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 40 })

        // 校准按钮（仅在未校准时显示）
        if (!this.isCalibrated) {
          Button('校准')
            .width(DeviceAdapter.scaleSize(80))
            .height(DeviceAdapter.scaleSize(32))
            .fontSize(DeviceAdapter.scaleFont(12))
            .fontColor('#FFFFFF')
            .backgroundColor(ThemeManager.getTheme().colors.secondary)
            .margin({ top: 20 })
            .onClick(() => this.startCalibration())
        }
      }
      .width('90%')
      .height('90%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .height('100%')
  }
}
