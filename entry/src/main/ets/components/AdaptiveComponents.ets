/**
 * 敲敲计 (TapCare) - 自适应 UI 组件
 * 圆形表盘适配组件
 */

import { DeviceAdapter } from '../common/DeviceAdapter';
import { ThemeManager } from '../common/ThemeManager';

/**
 * 自适应文本组件
 */
@Component
export struct AdaptiveText {
  @Prop text: string = '';
  @Prop baseFontSize: number = 16;
  @Prop fontWeight: FontWeight = FontWeight.Normal;
  @Prop fontColor: string = ThemeManager.getTheme().colors.text;
  @Prop textAlign: TextAlign = TextAlign.Center;

  build() {
    Text(this.text)
      .fontSize(DeviceAdapter.scaleFont(this.baseFontSize))
      .fontWeight(this.fontWeight)
      .fontColor(this.fontColor)
      .textAlign(this.textAlign)
  }
}

/**
 * 自适应按钮组件
 */
@Component
export struct AdaptiveButton {
  @Prop text: string = '';
  @Prop onTap: () => void = () => {};
  @Prop buttonColor: string = ThemeManager.getTheme().colors.primary;
  @Prop textColor: string = '#FFFFFF';
  @Prop width: number = 120;
  @Prop height: number = 44;
  @Prop fontSize: number = 16;
  @Prop enabled: boolean = true;

  build() {
    Button(this.text)
      .width(DeviceAdapter.scaleSize(this.width))
      .height(DeviceAdapter.scaleSize(this.height))
      .fontSize(DeviceAdapter.scaleFont(this.fontSize))
      .fontColor(this.textColor)
      .backgroundColor(this.enabled ? this.buttonColor : '#666666')
      .enabled(this.enabled)
      .onClick(() => {
        if (this.enabled) {
          this.onTap();
        }
      })
  }
}

/**
 * 圆形表盘布局容器
 */
@Component
export struct RoundWatchLayout {
  @BuilderParam content: () => void;
  @Prop backgroundColor: string = ThemeManager.getTheme().colors.background;

  build() {
    Stack() {
      // 圆形背景
      Circle()
        .width('100%')
        .height('100%')
        .fill(this.backgroundColor)

      // 内容区域（留出边缘）
      Column() {
        this.content()
      }
      .width('90%')
      .height('90%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}

/**
 * 计数显示组件
 */
@Component
export struct CountDisplay {
  @Prop currentCount: number = 0;
  @Prop targetCount: number = 100;
  @Prop label: string = '敲打次数';

  build() {
    Column() {
      // 标签
      Text(this.label)
        .fontSize(DeviceAdapter.scaleFont(14))
        .fontColor(ThemeManager.getTheme().colors.textSecondary)
        .margin({ bottom: 8 })

      // 计数
      Text(`${this.currentCount} / ${this.targetCount}`)
        .fontSize(DeviceAdapter.scaleFont(36))
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeManager.getTheme().colors.text)

      // 进度条
      Progress({ value: this.currentCount, total: this.targetCount })
        .width(DeviceAdapter.scaleSize(200))
        .height(DeviceAdapter.scaleSize(8))
        .color(ThemeManager.getTheme().colors.primary)
        .margin({ top: 16 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}

/**
 * 状态指示器组件
 */
@Component
export struct StatusIndicator {
  @Prop state: string = 'idle';
  @Prop duration: string = '0:00';

  @State private bgColor: string = '#333333';
  @State private textColor: string = '#FFFFFF';

  aboutToAppear() {
    this.updateColors();
  }

  private updateColors() {
    switch (this.state) {
      case 'counting':
        this.bgColor = '#2ECC71';
        this.textColor = '#FFFFFF';
        break;
      case 'paused':
        this.bgColor = '#F39C12';
        this.textColor = '#FFFFFF';
        break;
      case 'completed':
        this.bgColor = '#3498DB';
        this.textColor = '#FFFFFF';
        break;
      default:
        this.bgColor = '#333333';
        this.textColor = '#FFFFFF';
    }
  }

  build() {
    Row() {
      Text(this.state === 'idle' ? '准备' : 
           this.state === 'counting' ? '计数中' :
           this.state === 'paused' ? '已暂停' : '已完成')
        .fontSize(DeviceAdapter.scaleFont(12))
        .fontColor(this.textColor)
      
      Text(this.duration)
        .fontSize(DeviceAdapter.scaleFont(12))
        .fontColor(this.textColor)
        .margin({ left: 8 })
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor(this.bgColor)
    .borderRadius(DeviceAdapter.scaleSize(12))
  }
}

/**
 * 部位选择器组件
 */
@Component
export struct PartSelector {
  @Prop selectedPart: string = 'gallbladder_left';
  @Prop onPartChange: (part: string) => void = () => {};

  private parts: Array<{ id: string; label: string }> = [
    { id: 'gallbladder_left', label: '左胆经' },
    { id: 'gallbladder_right', label: '右胆经' },
    { id: 'pericardium', label: '心包经' },
    { id: 'sanjiao', label: '三焦经' }
  ];

  build() {
    Row() {
      ForEach(this.parts, (part) => {
        Text(part.label)
          .fontSize(DeviceAdapter.scaleFont(12))
          .fontColor(this.selectedPart === part.id ? 
            ThemeManager.getTheme().colors.primary : 
            ThemeManager.getTheme().colors.textSecondary)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.selectedPart === part.id ? 
            ThemeManager.getTheme().colors.surface : 'transparent')
          .borderRadius(DeviceAdapter.scaleSize(8))
          .onClick(() => this.onPartChange(part.id))
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
  }
}
