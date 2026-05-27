//
//  MATDemoTheme.h
//  zmaticoo-ios-demo
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MATDemoTheme : NSObject

+ (UIColor *)groupedBackgroundColor;
+ (UIColor *)cardBackgroundColor;
+ (UIColor *)primaryAccentColor;
+ (UIColor *)primaryTextColor;
+ (UIColor *)secondaryTextColor;
+ (UIColor *)tertiaryTextColor;
+ (UIColor *)cardBorderColor;
+ (UIColor *)mediaPlaceholderColor;
+ (UIColor *)adBadgeColor;

+ (void)applyCardStyleToView:(UIView *)view cornerRadius:(CGFloat)radius;
+ (void)applyPrimaryButtonStyle:(UIButton *)button;
+ (void)applySecondaryButtonStyle:(UIButton *)button;

/// Native card width (aligned with TopOn shell: ~86% screen, capped).
+ (CGFloat)nativeCardWidth;

@end

NS_ASSUME_NONNULL_END
