//
//  MATNativeAdRenderer.m
//  zmaticoo-ios-demo
//

#import "MATNativeAdRenderer.h"
#import "MATDemoTheme.h"
#import <MaticooSDK/MaticooSDK.h>

static const NSInteger kMATNativeTagRoot = 9001;

static const CGFloat kNativeCardPadding = 12.0;
static const CGFloat kNativeCardCornerRadius = 12.0;
static const CGFloat kNativeIconSize = 44.0;
static const CGFloat kNativeCTAHeight = 40.0;
static const CGFloat kNativeMediaMaxHeightRatio = 0.72;
static const CGFloat kNativeIconRowGap = 10.0;
static const CGFloat kNativeBodyTopGap = 8.0;
static const CGFloat kNativeCTATopGap = 10.0;
static const NSInteger kNativeBodyMaxLines = 2;
static NSString * const kNativeDefaultCTAText = @"Learn More";

@implementation MATNativeAdRenderer

+ (void)configureNativeAd:(MATNativeAd *)nativeAd {
    MATNativeAdOptions *options = [[MATNativeAdOptions alloc] init];
    MATVideoOptions *videoOptions = [[MATVideoOptions alloc] init];
    videoOptions.startMuted = YES;
    options.videoOptions = videoOptions;
    [nativeAd setNativeAdOptions:options];
}

+ (CGFloat)mediaAspectForElements:(MATNativeAdElements *)elements {
    CGFloat aspect = 16.0 / 9.0;
    MATMediaContent *media = elements.mediaContent;
    if (media && media.aspectRatio > 0.01 && media.aspectRatio <= 10.0) {
        aspect = media.aspectRatio;
    } else if (elements.icon.aspectRatio > 0.01) {
        aspect = elements.icon.aspectRatio;
    }
    return aspect;
}

+ (CGFloat)mediaHeightForElements:(MATNativeAdElements *)elements width:(CGFloat)width {
    CGFloat innerW = MAX(width - kNativeCardPadding * 2.0, 44.0);
    CGFloat aspect = [self mediaAspectForElements:elements];
    CGFloat mediaH = innerW / MAX(aspect, 0.01);
    return MIN(mediaH, width * kNativeMediaMaxHeightRatio);
}

+ (CGFloat)textBlockHeightForText:(NSString *)text
                             font:(UIFont *)font
                            width:(CGFloat)width
                        maxLines:(NSInteger)maxLines {
    if (text.length == 0 || maxLines <= 0) {
        return 0.0;
    }
    CGFloat maxHeight = ceil(font.lineHeight * (CGFloat)maxLines + font.leading * MAX((CGFloat)maxLines - 1.0, 0.0));
    CGRect bounds = [text boundingRectWithSize:CGSizeMake(width, maxHeight)
                                       options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                    attributes:@{ NSFontAttributeName: font }
                                       context:nil];
    return MIN(ceil(CGRectGetHeight(bounds)), maxHeight);
}

+ (CGFloat)preferredHeightForElements:(MATNativeAdElements *)elements width:(CGFloat)width {
    width = MAX(width, 280.0);
    CGFloat innerW = MAX(width - kNativeCardPadding * 2.0, 44.0);
    CGFloat mediaH = [self mediaHeightForElements:elements width:width];
    UIFont *bodyFont = [UIFont systemFontOfSize:13.0];
    CGFloat bodyH = [self textBlockHeightForText:elements.body
                                            font:bodyFont
                                           width:innerW
                                       maxLines:kNativeBodyMaxLines];
    if (bodyH < bodyFont.lineHeight && elements.body.length > 0) {
        bodyH = bodyFont.lineHeight;
    }

    return ceil(kNativeCardPadding
                + mediaH
                + kNativeIconRowGap
                + kNativeIconSize
                + kNativeBodyTopGap
                + bodyH
                + kNativeCTATopGap
                + kNativeCTAHeight
                + kNativeCardPadding);
}

+ (CGFloat)preferredHeightForNativeAd:(MATNativeAd *)nativeAd width:(CGFloat)width {
    if (!nativeAd.nativeElements) {
        return 320.0;
    }
    return [self preferredHeightForElements:nativeAd.nativeElements width:width];
}

+ (void)renderNativeAd:(MATNativeAd *)nativeAd inContainer:(UIView *)container {
    [self renderNativeAd:nativeAd inContainer:container width:[MATDemoTheme nativeCardWidth]];
}

+ (void)renderNativeAd:(MATNativeAd *)nativeAd inContainer:(UIView *)container width:(CGFloat)width {
    for (UIView *sub in container.subviews) {
        [sub removeFromSuperview];
    }
    NSArray *containerConstraints = [container.constraints copy];
    for (NSLayoutConstraint *constraint in containerConstraints) {
        [container removeConstraint:constraint];
    }

    MATNativeAdElements *elements = nativeAd.nativeElements;
    if (!elements) {
        return;
    }

    width = MAX(width, 280.0);
    CGFloat height = [self preferredHeightForElements:elements width:width];
    UIView *shellView = [self buildShellViewWithElements:elements width:width];
    shellView.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:shellView];

    [NSLayoutConstraint activateConstraints:@[
        [shellView.topAnchor constraintEqualToAnchor:container.topAnchor],
        [shellView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
        [shellView.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [shellView.widthAnchor constraintEqualToConstant:width],
        [shellView.heightAnchor constraintEqualToConstant:height],
    ]];

    MATMediaView *mediaView = [shellView viewWithTag:kMATNativeTagRoot + 1];
    UIImageView *iconView = [shellView viewWithTag:kMATNativeTagRoot + 2];
    UILabel *headlineLabel = [shellView viewWithTag:kMATNativeTagRoot + 3];
    UILabel *bodyLabel = [shellView viewWithTag:kMATNativeTagRoot + 4];
    UILabel *advertiserLabel = [shellView viewWithTag:kMATNativeTagRoot + 5];
    UILabel *ctaLabel = [shellView viewWithTag:kMATNativeTagRoot + 6];
    MATAdChoicesView *adChoicesView = [shellView viewWithTag:kMATNativeTagRoot + 7];
    UIView *mediaHostView = [shellView viewWithTag:kMATNativeTagRoot + 8];

    [adChoicesView setNativeAd:nativeAd];

    [nativeAd registerViewForInteraction:shellView
                               mediaView:mediaView
                          clickableViews:@[ctaLabel, headlineLabel, bodyLabel, iconView, mediaHostView]];
}

+ (UIView *)buildShellViewWithElements:(MATNativeAdElements *)elements width:(CGFloat)width {
    width = MAX(width, 280.0);
    CGFloat innerW = MAX(width - kNativeCardPadding * 2.0, 44.0);
    CGFloat mediaH = [self mediaHeightForElements:elements width:width];
    UIFont *bodyFont = [UIFont systemFontOfSize:13.0];
    CGFloat bodyH = [self textBlockHeightForText:elements.body
                                            font:bodyFont
                                           width:innerW
                                       maxLines:kNativeBodyMaxLines];
    if (bodyH < bodyFont.lineHeight && elements.body.length > 0) {
        bodyH = bodyFont.lineHeight;
    }

    UIView *shell = [[UIView alloc] init];
    [MATDemoTheme applyCardStyleToView:shell cornerRadius:kNativeCardCornerRadius];
    shell.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *mediaHostView = [[UIView alloc] init];
    mediaHostView.tag = kMATNativeTagRoot + 8;
    mediaHostView.translatesAutoresizingMaskIntoConstraints = NO;
    mediaHostView.backgroundColor = [MATDemoTheme mediaPlaceholderColor];
    mediaHostView.clipsToBounds = YES;
    mediaHostView.layer.cornerRadius = 8.0;
    [shell addSubview:mediaHostView];

    MATMediaView *mediaView = [[MATMediaView alloc] init];
    mediaView.tag = kMATNativeTagRoot + 1;
    mediaView.translatesAutoresizingMaskIntoConstraints = NO;
    mediaView.backgroundColor = [UIColor clearColor];
    [mediaHostView addSubview:mediaView];

    UILabel *adBadgeLabel = [[UILabel alloc] init];
    adBadgeLabel.text = @"AD";
    adBadgeLabel.font = [UIFont boldSystemFontOfSize:9.0];
    adBadgeLabel.textColor = [UIColor whiteColor];
    adBadgeLabel.backgroundColor = [MATDemoTheme adBadgeColor];
    adBadgeLabel.textAlignment = NSTextAlignmentCenter;
    adBadgeLabel.layer.cornerRadius = 3.0;
    adBadgeLabel.clipsToBounds = YES;
    adBadgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [shell addSubview:adBadgeLabel];

    MATAdChoicesView *adChoicesView = [[MATAdChoicesView alloc] init];
    adChoicesView.tag = kMATNativeTagRoot + 7;
    adChoicesView.translatesAutoresizingMaskIntoConstraints = NO;
    [shell addSubview:adChoicesView];

    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.tag = kMATNativeTagRoot + 2;
    iconView.contentMode = UIViewContentModeScaleAspectFill;
    iconView.clipsToBounds = YES;
    iconView.layer.cornerRadius = 8.0;
    iconView.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [iconView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [iconView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [iconView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [iconView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self applyImage:elements.icon toImageView:iconView];
    [shell addSubview:iconView];

    UILabel *headlineLabel = [self labelWithTag:kMATNativeTagRoot + 3
                                           text:elements.headline
                                           font:[UIFont boldSystemFontOfSize:15.0]
                                          color:[MATDemoTheme primaryTextColor]
                                    numberOfLines:2];
    [headlineLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [shell addSubview:headlineLabel];

    UILabel *advertiserLabel = [self labelWithTag:kMATNativeTagRoot + 5
                                             text:elements.advertiser
                                             font:[UIFont systemFontOfSize:11.0]
                                            color:[MATDemoTheme tertiaryTextColor]
                                      numberOfLines:1];
    advertiserLabel.hidden = (elements.advertiser.length == 0);
    [shell addSubview:advertiserLabel];

    UILabel *bodyLabel = [self labelWithTag:kMATNativeTagRoot + 4
                                       text:elements.body
                                       font:bodyFont
                                      color:[MATDemoTheme secondaryTextColor]
                                numberOfLines:kNativeBodyMaxLines];
    [bodyLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [bodyLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [shell addSubview:bodyLabel];

    NSString *ctaText = elements.callToAction.length > 0 ? elements.callToAction : kNativeDefaultCTAText;
    UILabel *ctaLabel = [self labelWithTag:kMATNativeTagRoot + 6
                                      text:ctaText
                                      font:[UIFont boldSystemFontOfSize:15.0]
                                     color:[UIColor whiteColor]
                               numberOfLines:1];
    ctaLabel.textAlignment = NSTextAlignmentCenter;
    ctaLabel.backgroundColor = [MATDemoTheme primaryAccentColor];
    ctaLabel.layer.cornerRadius = 8.0;
    ctaLabel.clipsToBounds = YES;
    ctaLabel.userInteractionEnabled = YES;
    [shell addSubview:ctaLabel];

    NSLayoutConstraint *iconWidth = [iconView.widthAnchor constraintEqualToConstant:kNativeIconSize];
    iconWidth.priority = UILayoutPriorityRequired;
    NSLayoutConstraint *iconHeight = [iconView.heightAnchor constraintEqualToConstant:kNativeIconSize];
    iconHeight.priority = UILayoutPriorityRequired;

    NSLayoutConstraint *bodyHeight = [bodyLabel.heightAnchor constraintGreaterThanOrEqualToConstant:bodyH];
    bodyHeight.priority = UILayoutPriorityRequired;

    [NSLayoutConstraint activateConstraints:@[
        [mediaHostView.topAnchor constraintEqualToAnchor:shell.topAnchor constant:kNativeCardPadding],
        [mediaHostView.leadingAnchor constraintEqualToAnchor:shell.leadingAnchor constant:kNativeCardPadding],
        [mediaHostView.trailingAnchor constraintEqualToAnchor:shell.trailingAnchor constant:-kNativeCardPadding],
        [mediaHostView.heightAnchor constraintEqualToConstant:mediaH],

        [mediaView.topAnchor constraintEqualToAnchor:mediaHostView.topAnchor],
        [mediaView.leadingAnchor constraintEqualToAnchor:mediaHostView.leadingAnchor],
        [mediaView.trailingAnchor constraintEqualToAnchor:mediaHostView.trailingAnchor],
        [mediaView.bottomAnchor constraintEqualToAnchor:mediaHostView.bottomAnchor],

        [adBadgeLabel.topAnchor constraintEqualToAnchor:mediaHostView.topAnchor constant:6.0],
        [adBadgeLabel.leadingAnchor constraintEqualToAnchor:mediaHostView.leadingAnchor constant:6.0],
        [adBadgeLabel.widthAnchor constraintEqualToConstant:22.0],
        [adBadgeLabel.heightAnchor constraintEqualToConstant:14.0],

        [adChoicesView.topAnchor constraintEqualToAnchor:adBadgeLabel.topAnchor],
        [adChoicesView.leadingAnchor constraintEqualToAnchor:adBadgeLabel.trailingAnchor constant:4.0],
        [adChoicesView.widthAnchor constraintEqualToConstant:52.0],
        [adChoicesView.heightAnchor constraintEqualToConstant:14.0],

        [iconView.topAnchor constraintEqualToAnchor:mediaHostView.bottomAnchor constant:kNativeIconRowGap],
        [iconView.leadingAnchor constraintEqualToAnchor:shell.leadingAnchor constant:kNativeCardPadding],
        iconWidth,
        iconHeight,

        [headlineLabel.topAnchor constraintEqualToAnchor:iconView.topAnchor],
        [headlineLabel.leadingAnchor constraintEqualToAnchor:iconView.trailingAnchor constant:10.0],
        [headlineLabel.trailingAnchor constraintEqualToAnchor:shell.trailingAnchor constant:-kNativeCardPadding],

        [advertiserLabel.topAnchor constraintEqualToAnchor:headlineLabel.bottomAnchor constant:2.0],
        [advertiserLabel.leadingAnchor constraintEqualToAnchor:headlineLabel.leadingAnchor],
        [advertiserLabel.trailingAnchor constraintEqualToAnchor:headlineLabel.trailingAnchor],
        [advertiserLabel.bottomAnchor constraintLessThanOrEqualToAnchor:iconView.bottomAnchor],

        [bodyLabel.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:kNativeBodyTopGap],
        [bodyLabel.leadingAnchor constraintEqualToAnchor:shell.leadingAnchor constant:kNativeCardPadding],
        [bodyLabel.trailingAnchor constraintEqualToAnchor:shell.trailingAnchor constant:-kNativeCardPadding],
        bodyHeight,

        [ctaLabel.topAnchor constraintEqualToAnchor:bodyLabel.bottomAnchor constant:kNativeCTATopGap],
        [ctaLabel.leadingAnchor constraintEqualToAnchor:shell.leadingAnchor constant:kNativeCardPadding],
        [ctaLabel.trailingAnchor constraintEqualToAnchor:shell.trailingAnchor constant:-kNativeCardPadding],
        [ctaLabel.bottomAnchor constraintEqualToAnchor:shell.bottomAnchor constant:-kNativeCardPadding],
        [ctaLabel.heightAnchor constraintEqualToConstant:kNativeCTAHeight],
    ]];

    return shell;
}

+ (UILabel *)labelWithTag:(NSInteger)tag
                     text:(NSString *)text
                     font:(UIFont *)font
                    color:(UIColor *)color
              numberOfLines:(NSInteger)numberOfLines {
    UILabel *label = [[UILabel alloc] init];
    label.tag = tag;
    label.font = font;
    label.textColor = color;
    label.text = text.length > 0 ? text : @"";
    label.numberOfLines = numberOfLines;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

+ (void)applyImage:(MATAdImage *)adImage toImageView:(UIImageView *)imageView {
    if (!adImage) {
        return;
    }
    if (adImage.image) {
        imageView.image = adImage.image;
        return;
    }
    NSURL *url = adImage.imageURL;
    if (!url) {
        return;
    }
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data || error) {
            return;
        }
        UIImage *image = [UIImage imageWithData:data];
        if (!image) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            imageView.image = image;
        });
    }];
    [task resume];
}

@end
