/**
 * SessionManager 单元测试
 * 测试会话状态机和敲打计数逻辑
 */

import { describe, it, expect } from '@ohos/hypium';
import { SessionManager } from '../../main/ets/services/SessionManager';
import { SessionState, SessionEvent, BodyPart } from '../../main/ets/models/TapDataModels';
import type { TapRecord } from '../../main/ets/models/TapDataModels';

describe('SessionManager', () => {
  let sessionManager: SessionManager;

  beforeEach(() => {
    sessionManager = SessionManager.getInstance();
    sessionManager.reset();
  });

  afterEach(() => {
    sessionManager.reset();
  });

  /**
   * 测试 1: 单例模式
   */
  it('should be singleton', () => {
    const instance1 = SessionManager.getInstance();
    const instance2 = SessionManager.getInstance();
    expect(instance1).toBe(instance2);
  });

  /**
   * 测试 2: 初始状态为 IDLE
   */
  it('should start in IDLE state', () => {
    const state = sessionManager.getState();
    expect(state).toBe(SessionState.IDLE);
  });

  /**
   * 测试 3: 开始会话
   */
  it('should transition from IDLE to COUNTING on START', () => {
    sessionManager.transition(SessionEvent.START);
    const state = sessionManager.getState();
    expect(state).toBe(SessionState.COUNTING);
  });

  /**
   * 测试 4: 检测敲打时计数增加
   */
  it('should increment count on tap detected', () => {
    sessionManager.transition(SessionEvent.START);
    
    const mockTapRecord: TapRecord = {
      id: 'test-tap-1',
      timestamp: Date.now(),
      part: BodyPart.GALLBLADDER_LEFT,
      force: 50,
      forceLevel: 'medium',
      confidence: 0.9,
      sessionId: 'test-session'
    };

    sessionManager.onTapDetected(mockTapRecord);
    const count = sessionManager.getCurrentCount();
    expect(count).toBe(1);
  });

  /**
   * 测试 5: 达到目标次数后状态变为 COMPLETED
   */
  it('should transition to COMPLETED when target reached', () => {
    sessionManager.setTarget(3);
    sessionManager.transition(SessionEvent.START);

    // 模拟 3 次敲打
    for (let i = 0; i < 3; i++) {
      const mockTapRecord: TapRecord = {
        id: `test-tap-${i}`,
        timestamp: Date.now(),
        part: BodyPart.GALLBLADDER_LEFT,
        force: 50,
        forceLevel: 'medium',
        confidence: 0.9,
        sessionId: 'test-session'
      };
      sessionManager.onTapDetected(mockTapRecord);
    }

    const state = sessionManager.getState();
    expect(state).toBe(SessionState.COMPLETED);
  });

  /**
   * 测试 6: 暂停会话
   */
  it('should transition to PAUSED on PAUSE event', () => {
    sessionManager.transition(SessionEvent.START);
    sessionManager.transition(SessionEvent.PAUSE);
    
    const state = sessionManager.getState();
    expect(state).toBe(SessionState.PAUSED);
  });

  /**
   * 测试 7: 恢复会话
   */
  it('should transition back to COUNTING on RESUME event', () => {
    sessionManager.transition(SessionEvent.START);
    sessionManager.transition(SessionEvent.PAUSE);
    sessionManager.transition(SessionEvent.RESUME);
    
    const state = sessionManager.getState();
    expect(state).toBe(SessionState.COUNTING);
  });

  /**
   * 测试 8: 重置会话
   */
  it('should reset to IDLE on RESET event', () => {
    sessionManager.transition(SessionEvent.START);
    sessionManager.onTapDetected({
      id: 'test-tap',
      timestamp: Date.now(),
      part: BodyPart.GALLBLADDER_LEFT,
      force: 50,
      forceLevel: 'medium',
      confidence: 0.9,
      sessionId: 'test-session'
    } as TapRecord);
    
    sessionManager.reset();
    const state = sessionManager.getState();
    expect(state).toBe(SessionState.IDLE);
    expect(sessionManager.getCurrentCount()).toBe(0);
  });

  /**
   * 测试 9: 进度计算
   */
  it('should calculate progress correctly', () => {
    sessionManager.setTarget(100);
    sessionManager.transition(SessionEvent.START);

    // 初始进度为 0
    expect(sessionManager.getProgress()).toBe(0);

    // 50 次敲打后进度为 50%
    for (let i = 0; i < 50; i++) {
      sessionManager.onTapDetected({
        id: `tap-${i}`,
        timestamp: Date.now(),
        part: BodyPart.GALLBLADDER_LEFT,
        force: 50,
        forceLevel: 'medium',
        confidence: 0.9,
        sessionId: 'test-session'
      } as TapRecord);
    }

    expect(sessionManager.getProgress()).toBe(50);
  });

  /**
   * 测试 10: 设置目标计数
   */
  it('should set target count', () => {
    sessionManager.setTarget(50);
    expect(sessionManager.getTargetCount()).toBe(50);

    sessionManager.setTarget(200);
    expect(sessionManager.getTargetCount()).toBe(200);
  });

  /**
   * 测试 11: 会话时长计算
   */
  it('should calculate session duration', () => {
    sessionManager.transition(SessionEvent.START);
    
    // 等待一小段时间
    const duration = sessionManager.getSessionDuration();
    expect(duration).toBeGreaterThanOrEqual(0);

    const formatted = sessionManager.getFormattedDuration();
    expect(formatted).toMatch(/^\d+:\d{2}$/); // 格式：M:SS
  });

  /**
   * 测试 12: 状态变化回调
   */
  it('should trigger state change callback', () => {
    let callbackCalled = false;
    let callbackState: SessionState | null = null;

    sessionManager.setOnStateChange((state: SessionState) => {
      callbackCalled = true;
      callbackState = state;
    });

    sessionManager.transition(SessionEvent.START);
    
    expect(callbackCalled).toBe(true);
    expect(callbackState).toBe(SessionState.COUNTING);
  });

  /**
   * 测试 13: 非活动状态检测
   */
  it('should report session is not active when idle', () => {
    expect(sessionManager.isSessionActive()).toBe(false);
  });

  /**
   * 测试 14: 活动状态检测
   */
  it('should report session is active when counting', () => {
    sessionManager.transition(SessionEvent.START);
    expect(sessionManager.isSessionActive()).toBe(true);
  });

  /**
   * 测试 15: 完成状态检测
   */
  it('should report session is completed', () => {
    sessionManager.setTarget(1);
    sessionManager.transition(SessionEvent.START);
    sessionManager.onTapDetected({
      id: 'tap-1',
      timestamp: Date.now(),
      part: BodyPart.GALLBLADDER_LEFT,
      force: 50,
      forceLevel: 'medium',
      confidence: 0.9,
      sessionId: 'test-session'
    } as TapRecord);

    expect(sessionManager.isCompleted()).toBe(true);
  });

  /**
   * 测试 16: 无效状态转换（IDLE 状态下 PAUSE）
   */
  it('should ignore invalid state transitions', () => {
    sessionManager.transition(SessionEvent.PAUSE); // IDLE 状态下无效
    const state = sessionManager.getState();
    expect(state).toBe(SessionState.IDLE); // 状态不变
  });

  /**
   * 测试 17: 获取敲打记录
   */
  it('should collect tap records', () => {
    sessionManager.transition(SessionEvent.START);

    sessionManager.onTapDetected({
      id: 'tap-1',
      timestamp: Date.now(),
      part: BodyPart.GALLBLADDER_LEFT,
      force: 50,
      forceLevel: 'medium',
      confidence: 0.9,
      sessionId: 'test-session'
    } as TapRecord);

    const records = sessionManager.getTapRecords();
    expect(records.length).toBe(1);
  });
});
