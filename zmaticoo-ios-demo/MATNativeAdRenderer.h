//
//  MATNativeAdRenderer.h
//  zmaticoo-ios-demo
//

#import <UIKit/UIKit.h>

@class MATNativeAd;

NS_ASSUME_NONNULL_BEGIN

/// Builds the native ad layout and calls iOS `registerViewForInteraction:` (Android: bindViews).
@interface MATNativeAdRenderer : NSObject

+ (void)configureNativeAd:(MATNativeAd *)nativeAd;
+ (CGFloat)preferredHeightForNativeAd:(MATNativeAd *)nativeAd width:(CGFloat)width;
+ (void)renderNativeAd:(MATNativeAd *)nativeAd inContainer:(UIView *)container;
+ (void)renderNativeAd:(MATNativeAd *)nativeAd inContainer:(UIView *)container width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
