/**
 * 敲敲计 (TapCare) - 主题管理器
 */

export interface ThemeColors {
  primary: string;
  secondary: string;
  background: string;
  surface: string;
  text: string;
  textSecondary: string;
  error: string;
  success: string;
  accent: string;
}

export interface Theme {
  isDark: boolean;
  colors: ThemeColors;
}

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
} as Theme;

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
} as Theme;

export class ThemeManager {
  private static currentTheme: Theme = DarkTheme;

  static getTheme(): Theme {
    return ThemeManager.currentTheme;
  }

  static setTheme(isDark: boolean): void {
    ThemeManager.currentTheme = isDark ? DarkTheme : LightTheme;
    console.info(`Theme changed to ${isDark ? 'dark' : 'light'}`);
  }

  static toggleTheme(): void {
    ThemeManager.setTheme(!ThemeManager.currentTheme.isDark);
  }

  static isDarkTheme(): boolean {
    return ThemeManager.currentTheme.isDark;
  }

  static getColor(name: string): string {
    const colors = ThemeManager.currentTheme.colors;
    switch (name) {
      case 'primary': return colors.primary;
      case 'secondary': return colors.secondary;
      case 'background': return colors.background;
      case 'surface': return colors.surface;
      case 'text': return colors.text;
      case 'textSecondary': return colors.textSecondary;
      case 'error': return colors.error;
      case 'success': return colors.success;
      case 'accent': return colors.accent;
      default: return colors.primary;
    }
  }
}
