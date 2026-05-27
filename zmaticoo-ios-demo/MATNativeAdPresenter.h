//
//  MATNativeAdPresenter.h
//  zmaticoo-ios-demo
//

#import <UIKit/UIKit.h>

@class MATNativeAd;

NS_ASSUME_NONNULL_BEGIN

@interface MATNativeAdPresenter : NSObject

+ (void)presentNativeAd:(MATNativeAd *)nativeAd
     fromViewController:(UIViewController *)host
              onDismiss:(nullable void (^)(void))onDismiss;

+ (void)dismissAnimated:(BOOL)animated;

+ (BOOL)isPresenting;

@end

NS_ASSUME_NONNULL_END
