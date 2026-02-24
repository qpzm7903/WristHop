/**
 * 敲敲计 (TapCare) - 主题管理器
 * 深色模式支持
 */

export interface Theme {
  isDark: boolean;
  colors: {
    primary: string;
    secondary: string;
    background: string;
    surface: string;
    text: string;
    textSecondary: string;
    error: string;
    success: string;
    accent: string;
  };
}

/**
 * 浅色主题
 */
export const LightTheme: Theme = {
  isDark: false,
  colors: {
    primary: '#FF6B6B',
    secondary: '#4ECDC4',
    background: '#FFFFFF',
    surface: '#F5F5F5',
    text: '#333333',
    textSecondary: '#666666',
    error: '#E74C3C',
    success: '#2ECC71',
    accent: '#FFE66D'
  }
};

/**
 * 深色主题（默认，省电）
 */
export const DarkTheme: Theme = {
  isDark: true,
  colors: {
    primary: '#FF6B6B',
    secondary: '#4ECDC4',
    background: '#1A1A1A',
    surface: '#2D2D2D',
    text: '#FFFFFF',
    textSecondary: '#AAAAAA',
    error: '#E74C3C',
    success: '#2ECC71',
    accent: '#FFE66D'
  }
};

/**
 * 主题管理器
 */
export class ThemeManager {
  private static currentTheme: Theme = DarkTheme; // 默认深色（省电）

  /**
   * 获取当前主题
   */
  static getTheme(): Theme {
    return this.currentTheme;
  }

  /**
   * 设置主题
   */
  static setTheme(isDark: boolean): void {
    this.currentTheme = isDark ? DarkTheme : LightTheme;
    console.info(`Theme changed to ${isDark ? 'dark' : 'light'}`);
  }

  /**
   * 切换主题
   */
  static toggleTheme(): void {
    this.setTheme(!this.currentTheme.isDark);
  }

  /**
   * 检查是否为深色主题
   */
  static isDarkTheme(): boolean {
    return this.currentTheme.isDark;
  }

  /**
   * 获取颜色值
   */
  static getColor(name: keyof Theme['colors']): string {
    return this.currentTheme.colors[name];
  }
}
