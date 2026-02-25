/**
 * 敲敲计 (TapCare) - 会话管理器
 * 状态机管理敲打会话
 */

import { SessionData, SessionState, SessionEvent, TapRecord, BodyPart } from '../models/TapDataModels';
import { generateId } from '../models/TapDataModels';

export class SessionManager {
  private static instance: SessionManager;
  private state: SessionState = SessionState.IDLE;
  private data: SessionData;
  private onStateChange?: (state: SessionState, data: SessionData) => void;

  private constructor() {
    this.data = this.initData();
  }

  static getInstance(): SessionManager {
    if (!SessionManager.instance) {
      SessionManager.instance = new SessionManager();
    }
    return SessionManager.instance;
  }

  private initData(): SessionData {
    return {
      state: SessionState.IDLE,
      currentPart: BodyPart.GALLBLADDER_LEFT,
      currentCount: 0,
      targetCount: 100,
      startTime: null,
      pauseTime: null,
      totalPauseDuration: 0,
      tapRecords: []
    };
  }

  /**
   * 状态转换
   */
  transition(event: SessionEvent, payload?: TapRecord): void {
    const previousState = this.state;

    switch (this.state) {
      case SessionState.IDLE:
        if (event === SessionEvent.START) {
          this.state = SessionState.COUNTING;
          this.data.startTime = Date.now();
          this.data.currentCount = 0;
          this.data.tapRecords = [];
          this.data.totalPauseDuration = 0;
          console.info('Session started');
        }
        break;

      case SessionState.COUNTING:
        if (event === SessionEvent.TAP_DETECTED) {
          this.data.currentCount++;
          this.data.tapRecords.push(payload as TapRecord);
          console.debug(`Tap detected: ${this.data.currentCount}/${this.data.targetCount}`);
          
          if (this.data.currentCount >= this.data.targetCount) {
            this.state = SessionState.COMPLETED;
            console.info('Session completed - target reached');
          }
        } else if (event === SessionEvent.PAUSE) {
          this.state = SessionState.PAUSED;
          this.data.pauseTime = Date.now();
          console.info('Session paused');
        } else if (event === SessionEvent.RESET) {
          this.state = SessionState.IDLE;
          this.data = this.initData();
          console.info('Session reset');
        }
        break;

      case SessionState.PAUSED:
        if (event === SessionEvent.RESUME) {
          this.state = SessionState.COUNTING;
          if (this.data.pauseTime) {
            this.data.totalPauseDuration += Date.now() - this.data.pauseTime;
            this.data.pauseTime = null;
          }
          console.info('Session resumed');
        } else if (event === SessionEvent.RESET) {
          this.state = SessionState.IDLE;
          this.data = this.initData();
          console.info('Session reset from paused');
        }
        break;

      case SessionState.COMPLETED:
        if (event === SessionEvent.RESET) {
          this.state = SessionState.IDLE;
          this.data = this.initData();
          console.info('Session reset from completed');
        }
        break;
    }

    this.data.state = this.state;
    
    if (this.state !== previousState && this.onStateChange) {
      this.onStateChange(this.state, this.data);
    }
  }

  /**
   * 处理敲打事件
   */
  onTapDetected(tapRecord: TapRecord): void {
    if (this.state === SessionState.COUNTING) {
      this.transition(SessionEvent.TAP_DETECTED, tapRecord);
    }
  }

  /**
   * 获取会话时长（不含暂停）
   */
  getSessionDuration(): number {
    if (!this.data.startTime) return 0;
    
    const elapsed = Date.now() - this.data.startTime - this.data.totalPauseDuration;
    return Math.max(0, elapsed);
  }

  /**
   * 获取格式化的会话时长
   */
  getFormattedDuration(): string {
    const duration = this.getSessionDuration();
    const minutes = Math.floor(duration / 60000);
    const seconds = Math.floor((duration % 60000) / 1000);
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  }

  /**
   * 设置状态变更回调
   */
  setOnStateChange(callback: (state: SessionState, data: SessionData) => void): void {
    this.onStateChange = callback;
  }

  /**
   * 设置目标计数
   */
  setTarget(count: number): void {
    this.data.targetCount = Math.max(1, count);
  }

  /**
   * 切换部位
   */
  switchPart(part: BodyPart): void {
    if (this.state === SessionState.IDLE) {
      this.data.currentPart = part;
    }
  }

  /**
   * 获取当前部位
   */
  getCurrentPart(): BodyPart {
    return this.data.currentPart;
  }

  /**
   * 获取当前计数
   */
  getCurrentCount(): number {
    return this.data.currentCount;
  }

  /**
   * 获取目标计数
   */
  getTargetCount(): number {
    return this.data.targetCount;
  }

  /**
   * 获取进度百分比
   */
  getProgress(): number {
    if (this.data.targetCount === 0) return 0;
    return Math.min(100, Math.round((this.data.currentCount / this.data.targetCount) * 100));
  }

  getData(): SessionData {
    return {
      state: this.data.state,
      currentPart: this.data.currentPart,
      currentCount: this.data.currentCount,
      targetCount: this.data.targetCount,
      startTime: this.data.startTime,
      pauseTime: this.data.pauseTime,
      totalPauseDuration: this.data.totalPauseDuration,
      tapRecords: [...this.data.tapRecords]
    };
  }

  getState(): SessionState {
    return this.state;
  }

  /**
   * 获取敲打记录
   */
  getTapRecords(): TapRecord[] {
    return [...this.data.tapRecords];
  }

  /**
   * 检查会话是否在进行中
   */
  isSessionActive(): boolean {
    return this.state === SessionState.COUNTING || this.state === SessionState.PAUSED;
  }

  /**
   * 检查会话是否完成
   */
  isCompleted(): boolean {
    return this.state === SessionState.COMPLETED;
  }

  /**
   * 重置会话
   */
  reset(): void {
    this.transition(SessionEvent.RESET);
  }
}
