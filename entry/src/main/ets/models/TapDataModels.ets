/**
 * 敲敲计 (TapCare) - 数据模型
 * 包含所有核心数据结构和枚举
 */

/**
 * 身体部位枚举
 */
export enum BodyPart {
  GALLBLADDER_LEFT = 'gallbladder_left',   // 左胆经
  GALLBLADDER_RIGHT = 'gallbladder_right', // 右胆经
  PERICARDIUM = 'pericardium',             // 心包经
  SANJIAO = 'sanjiao',                     // 三焦经
  CUSTOM = 'custom'                        // 自定义
}

/**
 * 力度等级
 */
export enum ForceLevel {
  LIGHT = 'light',     // 轻拍 (0-33)
  MEDIUM = 'medium',   // 中等 (34-66)
  STRONG = 'strong'    // 重拍 (67-100)
}

/**
 * 会话状态枚举
 */
export enum SessionState {
  IDLE = 'idle',           // 空闲，未开始
  COUNTING = 'counting',   // 正在计数
  PAUSED = 'paused',       // 已暂停
  COMPLETED = 'completed'  // 已完成目标
}

/**
 * 会话事件枚举
 */
export enum SessionEvent {
  START = 'start',         // 开始
  PAUSE = 'pause',         // 暂停
  RESUME = 'resume',       // 恢复
  RESET = 'reset',         // 重置
  TAP_DETECTED = 'tap',    // 检测到敲打
  TARGET_REACHED = 'target_reached' // 达到目标
}

/**
 * 校准结果
 */
export interface CalibrationResult {
  wearingHand: 'left' | 'right';
  baselineAccel: { x: number, y: number, z: number };
  baselineGyro: { x: number, y: number, z: number };
  sensitivity: number;
  calibratedAt: number;
}

/**
 * 单次敲打记录
 */
export interface TapRecord {
  id: string;                    // 唯一标识
  timestamp: number;             // 时间戳
  part: BodyPart;                // 部位
  force: number;                 // 力度值 (0-100)
  forceLevel: ForceLevel;        // 力度等级
  confidence: number;            // 检测置信度 (0-1)
  sessionId: string;             // 所属会话 ID
  accelerometerData?: {          // 原始加速度数据（可选）
    x: number;
    y: number;
    z: number;
  };
}

/**
 * 会话统计数据
 */
export interface SessionStatistics {
  averageForce: number;          // 平均力度
  averageInterval: number;       // 平均敲打间隔
  rhythmScore: number;           // 节奏评分 (0-100)
  durationMs: number;            // 实际时长
  forceDistribution: {           // 力度分布
    light: number;
    medium: number;
    strong: number;
  };
  confidence: number;            // 整体置信度
}

/**
 * 敲打会话
 */
export interface TapSession {
  id: string;                    // 会话 ID
  startTime: number;             // 开始时间
  endTime: number | null;        // 结束时间
  totalDuration: number;         // 总时长
  pauseDuration: number;         // 暂停时长
  part: BodyPart;                // 练习部位
  targetCount: number;           // 目标次数
  actualCount: number;           // 实际次数
  completed: boolean;            // 是否完成
  records: TapRecord[];          // 敲打记录
  statistics: SessionStatistics; // 统计数据
  calibration: CalibrationResult; // 校准信息
}

/**
 * 会话数据（运行时）
 */
export interface SessionData {
  state: SessionState;
  currentPart: BodyPart;
  currentCount: number;
  targetCount: number;
  startTime: number | null;
  pauseTime: number | null;
  totalPauseDuration: number;
  tapRecords: TapRecord[];
}

/**
 * 每日数据汇总
 */
export interface DailySummary {
  date: string;                  // YYYY-MM-DD
  totalSessions: number;         // 会话总数
  totalTaps: number;             // 敲打总数
  totalDuration: number;         // 总时长
  partBreakdown: Map<BodyPart, { // 分部位统计
    count: number;
    duration: number;
  }>;
  averageForce: number;          // 平均力度
  streakDays: number;            // 连续天数
  goalAchieved: boolean;         // 是否达成日目标
}

/**
 * 用户设置
 */
export interface UserSettings {
  wearingHand: 'left' | 'right'; // 佩戴手
  targetPerSession: number;      // 每次目标
  targetPerDay: number;          // 每日目标
  hapticFeedback: boolean;       // 触觉反馈
  hapticIntensity: number;       // 反馈强度 (1-3)
  soundFeedback: boolean;        // 声音反馈
  reminder: {                    // 提醒设置
    enabled: boolean;
    time: string;                // HH:mm
    message: string;
  };
  sensitivity: number;           // 检测灵敏度 (0.5-2.0)
  calibration: CalibrationResult | null;
}

/**
 * 工具函数：根据力度值获取力度等级
 */
export function getForceLevel(force: number): ForceLevel {
  if (force <= 33) {
    return ForceLevel.LIGHT;
  } else if (force <= 66) {
    return ForceLevel.MEDIUM;
  } else {
    return ForceLevel.STRONG;
  }
}

/**
 * 工具函数：生成唯一 ID
 */
export function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}
