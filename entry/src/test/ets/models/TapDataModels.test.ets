/**
 * 数据模型单元测试
 * 测试枚举、接口和工具函数
 */

import { describe, it, expect } from '@ohos/hypium';
import { 
  BodyPart, 
  ForceLevel, 
  SessionState, 
  SessionEvent,
  getForceLevel,
  generateId
} from '../../main/ets/models/TapDataModels';

describe('TapDataModels', () => {
  
  /**
   * 测试 BodyPart 枚举
   */
  describe('BodyPart', () => {
    it('should have correct enum values', () => {
      expect(BodyPart.GALLBLADDER_LEFT).toBe('gallbladder_left');
      expect(BodyPart.GALLBLADDER_RIGHT).toBe('gallbladder_right');
      expect(BodyPart.PERICARDIUM).toBe('pericardium');
      expect(BodyPart.SANJIAO).toBe('sanjiao');
      expect(BodyPart.CUSTOM).toBe('custom');
    });

    it('should include all body parts', () => {
      const parts = Object.values(BodyPart);
      expect(parts.length).toBe(5);
    });
  });

  /**
   * 测试 ForceLevel 枚举
   */
  describe('ForceLevel', () => {
    it('should have correct enum values', () => {
      expect(ForceLevel.LIGHT).toBe('light');
      expect(ForceLevel.MEDIUM).toBe('medium');
      expect(ForceLevel.STRONG).toBe('strong');
    });

    it('should include all force levels', () => {
      const levels = Object.values(ForceLevel);
      expect(levels.length).toBe(3);
    });
  });

  /**
   * 测试 SessionState 枚举
   */
  describe('SessionState', () => {
    it('should have correct enum values', () => {
      expect(SessionState.IDLE).toBe('idle');
      expect(SessionState.COUNTING).toBe('counting');
      expect(SessionState.PAUSED).toBe('paused');
      expect(SessionState.COMPLETED).toBe('completed');
    });
  });

  /**
   * 测试 SessionEvent 枚举
   */
  describe('SessionEvent', () => {
    it('should have correct enum values', () => {
      expect(SessionEvent.START).toBe('start');
      expect(SessionEvent.PAUSE).toBe('pause');
      expect(SessionEvent.RESUME).toBe('resume');
      expect(SessionEvent.RESET).toBe('reset');
      expect(SessionEvent.TAP_DETECTED).toBe('tap');
      expect(SessionEvent.TARGET_REACHED).toBe('target_reached');
    });
  });

  /**
   * 测试 getForceLevel 工具函数
   */
  describe('getForceLevel', () => {
    it('should return LIGHT for force 0-33', () => {
      expect(getForceLevel(0)).toBe(ForceLevel.LIGHT);
      expect(getForceLevel(15)).toBe(ForceLevel.LIGHT);
      expect(getForceLevel(33)).toBe(ForceLevel.LIGHT);
    });

    it('should return MEDIUM for force 34-66', () => {
      expect(getForceLevel(34)).toBe(ForceLevel.MEDIUM);
      expect(getForceLevel(50)).toBe(ForceLevel.MEDIUM);
      expect(getForceLevel(66)).toBe(ForceLevel.MEDIUM);
    });

    it('should return STRONG for force 67-100', () => {
      expect(getForceLevel(67)).toBe(ForceLevel.STRONG);
      expect(getForceLevel(80)).toBe(ForceLevel.STRONG);
      expect(getForceLevel(100)).toBe(ForceLevel.STRONG);
    });

    it('should handle boundary values', () => {
      expect(getForceLevel(33)).toBe(ForceLevel.LIGHT);
      expect(getForceLevel(34)).toBe(ForceLevel.MEDIUM);
      expect(getForceLevel(66)).toBe(ForceLevel.MEDIUM);
      expect(getForceLevel(67)).toBe(ForceLevel.STRONG);
    });
  });

  /**
   * 测试 generateId 工具函数
   */
  describe('generateId', () => {
    it('should generate non-empty string', () => {
      const id = generateId();
      expect(id).not.toBe('');
      expect(typeof id).toBe('string');
    });

    it('should generate unique IDs', () => {
      const id1 = generateId();
      const id2 = generateId();
      expect(id1).not.toBe(id2);
    });

    it('should generate IDs with timestamp prefix', () => {
      const id = generateId();
      const timestamp = id.split('-')[0];
      expect(parseInt(timestamp)).toBeGreaterThan(0);
    });

    it('should generate IDs with random suffix', () => {
      const id1 = generateId();
      const id2 = generateId();
      
      const suffix1 = id1.split('-')[1];
      const suffix2 = id2.split('-')[1];
      
      expect(suffix1).not.toBe(suffix2);
      expect(suffix1.length).toBeGreaterThan(0);
      expect(suffix2.length).toBeGreaterThan(0);
    });

    it('should generate consistent format', () => {
      const id = generateId();
      const parts = id.split('-');
      expect(parts.length).toBe(2);
      expect(parts[0]).toMatch(/^\d+$/); // 时间戳是数字
    });
  });

  /**
   * 性能测试：generateId 生成速度
   */
  it('should generate 1000 IDs in less than 100ms', () => {
    const startTime = Date.now();
    
    for (let i = 0; i < 1000; i++) {
      generateId();
    }
    
    const elapsed = Date.now() - startTime;
    expect(elapsed).toBeLessThan(100);
  });

  /**
   * 测试 ID 格式有效性
   */
  it('should generate IDs with valid format', () => {
    for (let i = 0; i < 100; i++) {
      const id = generateId();
      expect(id).toMatch(/^\d+-[a-z0-9]+$/);
    }
  });
});
