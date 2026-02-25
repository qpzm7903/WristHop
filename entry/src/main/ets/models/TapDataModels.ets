/**
 * 敲敲计 (TapCare) - 数据模型
 * 包含所有核心数据结构和枚举
 */

export enum BodyPart {
  GALLBLADDER_LEFT = 'gallbladder_left',
  GALLBLADDER_RIGHT = 'gallbladder_right',
  PERICARDIUM = 'pericardium',
  SANJIAO = 'sanjiao',
  CUSTOM = 'custom'
}

export enum ForceLevel {
  LIGHT = 'light',
  MEDIUM = 'medium',
  STRONG = 'strong'
}

export enum SessionState {
  IDLE = 'idle',
  COUNTING = 'counting',
  PAUSED = 'paused',
  COMPLETED = 'completed'
}

export enum SessionEvent {
  START = 'start',
  PAUSE = 'pause',
  RESUME = 'resume',
  RESET = 'reset',
  TAP_DETECTED = 'tap',
  TARGET_REACHED = 'target_reached'
}

export interface BaselineData {
  x: number;
  y: number;
  z: number;
}

export interface CalibrationResult {
  wearingHand: 'left' | 'right';
  baselineAccel: BaselineData;
  baselineGyro: BaselineData;
  sensitivity: number;
  calibratedAt: number;
}

export interface AccelerometerData {
  x: number;
  y: number;
  z: number;
}

export interface TapRecord {
  id: string;
  timestamp: number;
  part: BodyPart;
  force: number;
  forceLevel: ForceLevel;
  confidence: number;
  sessionId: string;
  accelerometerData?: AccelerometerData;
}

export interface ForceDistribution {
  light: number;
  medium: number;
  strong: number;
}

export interface SessionStatistics {
  averageForce: number;
  averageInterval: number;
  rhythmScore: number;
  durationMs: number;
  forceDistribution: ForceDistribution;
  confidence: number;
}

export interface TapSession {
  id: string;
  startTime: number;
  endTime: number | null;
  totalDuration: number;
  pauseDuration: number;
  part: BodyPart;
  targetCount: number;
  actualCount: number;
  completed: boolean;
  records: TapRecord[];
  statistics: SessionStatistics;
  calibration: CalibrationResult;
}

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

export interface PartBreakdown {
  count: number;
  duration: number;
}

export interface DailySummary {
  date: string;
  totalSessions: number;
  totalTaps: number;
  totalDuration: number;
  partBreakdown: Map<BodyPart, PartBreakdown>;
  averageForce: number;
  streakDays: number;
  goalAchieved: boolean;
}

export interface ReminderSettings {
  enabled: boolean;
  time: string;
  message: string;
}

export interface UserSettings {
  wearingHand: 'left' | 'right';
  targetPerSession: number;
  targetPerDay: number;
  hapticFeedback: boolean;
  hapticIntensity: number;
  soundFeedback: boolean;
  reminder: ReminderSettings;
  sensitivity: number;
  calibration: CalibrationResult | null;
}

export function getForceLevel(force: number): ForceLevel {
  if (force <= 33) {
    return ForceLevel.LIGHT;
  } else if (force <= 66) {
    return ForceLevel.MEDIUM;
  } else {
    return ForceLevel.STRONG;
  }
}

export function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}
