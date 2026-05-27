//
//  MATNativeAdPresenter.m
//  zmaticoo-ios-demo
//

#import "MATNativeAdPresenter.h"
#import "MATDemoTheme.h"
#import "MATNativeAdRenderer.h"
#import <MaticooSDK/MaticooSDK.h>

static const CGFloat kNativeCloseBtnSize = 22.0;
static const CGFloat kNativeCloseHitInset = 8.0;
static const CGFloat kNativeCloseCornerOffset = 8.0;
static const CGFloat kDiag = 0.70710678118654752440;

static UIView *g_overlay = nil;
static void (^g_onDismiss)(void) = nil;

@interface MATNativeAdOverlayView : UIView
@end

@implementation MATNativeAdOverlayView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self) {
        return nil;
    }
    return hit;
}

@end

@interface MATNativeCloseButton : UIButton
@end

@implementation MATNativeCloseButton

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect hitFrame = CGRectInset(self.bounds, -kNativeCloseHitInset, -kNativeCloseHitInset);
    return CGRectContainsPoint(hitFrame, point);
}

@end

@implementation MATNativeAdPresenter

+ (BOOL)isPresenting {
    return g_overlay != nil;
}

+ (UIButton *)makeCloseButton {
    MATNativeCloseButton *closeBtn = [MATNativeCloseButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold];
    [closeBtn setTitleColor:[UIColor colorWithWhite:0.35 alpha:1.0] forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.95];
    closeBtn.layer.cornerRadius = kNativeCloseBtnSize / 2.0;
    closeBtn.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;
    closeBtn.layer.borderWidth = 0.5;
    closeBtn.clipsToBounds = YES;
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    closeBtn.accessibilityLabel = @"Close ad";
    closeBtn.accessibilityTraits = UIAccessibilityTraitButton;
    [closeBtn addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    return closeBtn;
}

+ (void)closeTapped {
    [self dismissAnimated:YES];
}

+ (void)dismissAnimated:(BOOL)animated {
    if (!g_overlay) {
        return;
    }

    UIView *overlay = g_overlay;
    void (^onDismiss)(void) = [g_onDismiss copy];
    g_overlay = nil;
    g_onDismiss = nil;

    void (^cleanup)(void) = ^{
        [overlay removeFromSuperview];
        if (onDismiss) {
            onDismiss();
        }
    };

    if (!animated) {
        cleanup();
        return;
    }

    overlay.alpha = 1.0;
    [UIView animateWithDuration:0.2 animations:^{
        overlay.alpha = 0.0;
    } completion:^(BOOL finished) {
        cleanup();
    }];
}

+ (void)presentNativeAd:(MATNativeAd *)nativeAd
     fromViewController:(UIViewController *)host
              onDismiss:(void (^)(void))onDismiss {
    if (!nativeAd || !host.view) {
        return;
    }

    [self dismissAnimated:NO];
    g_onDismiss = [onDismiss copy];

    CGFloat width = [MATDemoTheme nativeCardWidth];
    CGFloat shellHeight = [MATNativeAdRenderer preferredHeightForNativeAd:nativeAd width:width];

    CGFloat diagonalShift = kNativeCloseCornerOffset * kDiag;
    CGFloat topInset = ceil(kNativeCloseBtnSize / 2.0 + diagonalShift);
    CGFloat wrapperHeight = shellHeight + topInset;

    MATNativeAdOverlayView *overlay = [[MATNativeAdOverlayView alloc] initWithFrame:host.view.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
    overlay.tag = 9001;

    UIView *wrapper = [[UIView alloc] init];
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
    wrapper.clipsToBounds = NO;
    wrapper.layer.shadowColor = [UIColor blackColor].CGColor;
    wrapper.layer.shadowOffset = CGSizeMake(0, 4);
    wrapper.layer.shadowRadius = 12.0;
    wrapper.layer.shadowOpacity = 0.2;
    [overlay addSubview:wrapper];

    UIView *shellHost = [[UIView alloc] init];
    shellHost.translatesAutoresizingMaskIntoConstraints = NO;
    shellHost.clipsToBounds = NO;
    [wrapper addSubview:shellHost];

    [MATNativeAdRenderer renderNativeAd:nativeAd inContainer:shellHost width:width];

    UIButton *closeButton = [self makeCloseButton];
    [overlay addSubview:closeButton];

    [NSLayoutConstraint activateConstraints:@[
        [wrapper.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [wrapper.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [wrapper.widthAnchor constraintEqualToConstant:width],
        [wrapper.heightAnchor constraintEqualToConstant:wrapperHeight],

        [shellHost.leadingAnchor constraintEqualToAnchor:wrapper.leadingAnchor],
        [shellHost.trailingAnchor constraintEqualToAnchor:wrapper.trailingAnchor],
        [shellHost.topAnchor constraintEqualToAnchor:wrapper.topAnchor constant:topInset],
        [shellHost.heightAnchor constraintEqualToConstant:shellHeight],

        [closeButton.widthAnchor constraintEqualToConstant:kNativeCloseBtnSize],
        [closeButton.heightAnchor constraintEqualToConstant:kNativeCloseBtnSize],
        [closeButton.centerXAnchor constraintEqualToAnchor:wrapper.trailingAnchor constant:diagonalShift],
        [closeButton.centerYAnchor constraintEqualToAnchor:wrapper.topAnchor constant:topInset - diagonalShift],
    ]];

    [host.view addSubview:overlay];
    [overlay bringSubviewToFront:closeButton];
    g_overlay = overlay;

    wrapper.transform = CGAffineTransformMakeScale(0.92, 0.92);
    wrapper.alpha = 0.0;
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        wrapper.transform = CGAffineTransformIdentity;
        wrapper.alpha = 1.0;
    } completion:nil];
}

@end
