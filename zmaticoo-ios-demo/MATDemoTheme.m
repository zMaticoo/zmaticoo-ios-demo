//
//  MATDemoTheme.m
//  zmaticoo-ios-demo
//

#import "MATDemoTheme.h"

static const CGFloat kNativeCardScreenMargin = 28.0;
static const CGFloat kNativeCardMaxWidth = 360.0;
static const CGFloat kNativeCardMinWidth = 300.0;
static const CGFloat kNativeCardWidthRatio = 0.86;

@implementation MATDemoTheme

+ (UIColor *)groupedBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGroupedBackgroundColor];
    }
    return [UIColor groupTableViewBackgroundColor];
}

+ (UIColor *)cardBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondarySystemGroupedBackgroundColor];
    }
    return [UIColor whiteColor];
}

+ (UIColor *)primaryAccentColor {
    return [UIColor colorWithRed:0.12 green:0.52 blue:0.98 alpha:1.0];
}

+ (UIColor *)primaryTextColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithWhite:0.12 alpha:1.0];
    }
    return [UIColor blackColor];
}

+ (UIColor *)secondaryTextColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithWhite:0.35 alpha:1.0];
    }
    return [UIColor darkGrayColor];
}

+ (UIColor *)tertiaryTextColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithWhite:0.55 alpha:1.0];
    }
    return [UIColor grayColor];
}

+ (UIColor *)cardBorderColor {
    return [UIColor colorWithWhite:0.90 alpha:1.0];
}

+ (UIColor *)mediaPlaceholderColor {
    return [UIColor colorWithWhite:0.96 alpha:1.0];
}

+ (UIColor *)adBadgeColor {
    return [UIColor colorWithRed:0.95 green:0.45 blue:0.15 alpha:1.0];
}

+ (void)applyCardStyleToView:(UIView *)view cornerRadius:(CGFloat)radius {
    view.backgroundColor = [UIColor whiteColor];
    view.layer.cornerRadius = radius;
    view.layer.borderColor = [self cardBorderColor].CGColor;
    view.layer.borderWidth = 0.5;
    view.clipsToBounds = YES;
}

+ (void)applyPrimaryButtonStyle:(UIButton *)button {
    button.layer.cornerRadius = 10.0;
    button.layer.masksToBounds = YES;
    button.contentEdgeInsets = UIEdgeInsetsMake(11, 14, 11, 14);
    button.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.backgroundColor = [self primaryAccentColor];
}

+ (void)applySecondaryButtonStyle:(UIButton *)button {
    button.layer.cornerRadius = 10.0;
    button.layer.masksToBounds = YES;
    button.contentEdgeInsets = UIEdgeInsetsMake(11, 14, 11, 14);
    button.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
    button.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    button.layer.borderWidth = 0.5;
    button.layer.borderColor = [self cardBorderColor].CGColor;
    [button setTitleColor:[self primaryTextColor] forState:UIControlStateNormal];
}

+ (CGFloat)nativeCardWidth {
    CGFloat screenW = CGRectGetWidth(UIScreen.mainScreen.bounds);
    CGFloat width = floor(screenW * kNativeCardWidthRatio);
    width = MIN(width, kNativeCardMaxWidth);
    width = MAX(width, kNativeCardMinWidth);
    width = MIN(width, screenW - kNativeCardScreenMargin * 2.0);
    return MAX(width, 280.0);
}

@end
