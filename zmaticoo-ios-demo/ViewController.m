//
//  ViewController.m
//  zmaticoo-ios-demo
//

#import "ViewController.h"
#import "MATDemoConfig.h"
#import "MATDemoLog.h"
#import "MATDemoTheme.h"
#import "MATNativeAdRenderer.h"
#import "MATNativeAdPresenter.h"
#import "NativeListViewController.h"
#import "SettingViewController.h"
#import <MaticooSDK/MaticooSDK.h>

@interface ViewController () <MATBannerAdDelegate, MATInterstitialAdDelegate, MATRewardedVideoAdDelegate, MATNativeAdDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *bannerStatusLabel;
@property (nonatomic, strong) UIView *bannerContainer;
@property (nonatomic, strong) MATBannerAd *bannerAd;
@property (nonatomic, strong) UILabel *interstitialStatusLabel;
@property (nonatomic, strong) UIButton *interstitialShowButton;
@property (nonatomic, strong) MATInterstitialAd *interstitialAd;
@property (nonatomic, strong) UILabel *rewardStatusLabel;
@property (nonatomic, strong) UIButton *rewardShowButton;
@property (nonatomic, strong) MATRewardedVideoAd *rewardedVideoAd;
@property (nonatomic, strong) UILabel *nativeStatusLabel;
@property (nonatomic, strong) MATNativeAd *nativeAd;
@property (nonatomic, strong) UIView *loadingOverlay;
/// 最近一次 Waterfall load 成功对应的 Ids（SDK 新回调带回；show 时回传，Waterfall 下 SDK 忽略匹配）
@property (nonatomic, strong) MATMaticooIds *interstitialIds;
@property (nonatomic, strong) MATMaticooIds *rewardIds;
// Header Bidding（插屏）
@property (nonatomic, strong) UILabel *hbInterstitialStatusLabel;
@property (nonatomic, strong) UIButton *hbInterstitialShowButton;
@property (nonatomic, strong) MATInterstitialAd *hbInterstitialAd;
@property (nonatomic, strong) MATMaticooIds *hbInterstitialIds;
// Header Bidding（激励视频）
@property (nonatomic, strong) UILabel *hbRewardStatusLabel;
@property (nonatomic, strong) UIButton *hbRewardShowButton;
@property (nonatomic, strong) MATRewardedVideoAd *hbRewardedVideoAd;
@property (nonatomic, strong) MATMaticooIds *hbRewardIds;
// Header Bidding（Banner）
@property (nonatomic, strong) UILabel *hbBannerStatusLabel;
@property (nonatomic, strong) UIView *hbBannerContainer;
@property (nonatomic, strong) MATBannerAd *hbBannerAd;
// Header Bidding（Native）
@property (nonatomic, strong) UILabel *hbNativeStatusLabel;
@property (nonatomic, strong) MATNativeAd *hbNativeAd;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [MATDemoTheme groupedBackgroundColor];
    [self buildLayout];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.loadingOverlay.superview) {
        self.loadingOverlay.frame = self.view.bounds;
    }
}

- (void)dealloc {
    [self.bannerAd destroy];
    [self.hbBannerAd destroy];
    [self.hbNativeAd destroy];
    [MATInterstitialAd destroy:@[MAT_DEMO_INTERSTITIAL_PLACEMENT_ID]];
    [MATRewardedVideoAd destroy:@[MAT_DEMO_REWARD_PLACEMENT_ID]];
    [MATInterstitialAd destroy:@[MAT_DEMO_HB_INTERSTITIAL_PLACEMENT_ID]];
    [MATRewardedVideoAd destroy:@[MAT_DEMO_HB_REWARD_PLACEMENT_ID]];
    [self destroyNativeAd];
}

#pragma mark - UI

- (UIView *)headerLogoContainer {
    UIView *wrap = [[UIView alloc] init];
    wrap.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_maticoo"]];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.accessibilityLabel = @"zMaticoo";
    [wrap addSubview:imageView];

    static const CGFloat kLogoHeight = 80;
    [NSLayoutConstraint activateConstraints:@[
        [imageView.centerXAnchor constraintEqualToAnchor:wrap.centerXAnchor],
        [imageView.topAnchor constraintEqualToAnchor:wrap.topAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:wrap.bottomAnchor],
        [imageView.heightAnchor constraintEqualToConstant:kLogoHeight],
        [imageView.widthAnchor constraintLessThanOrEqualToAnchor:wrap.widthAnchor],
        [wrap.heightAnchor constraintEqualToConstant:kLogoHeight],
    ]];

    return wrap;
}

- (NSAttributedString *)headerTitleAttributedString {
    NSString *line1 = @"zMaticoo SDK Demo";
    NSString *ver = [[MaticooAds shareSDK] getSDKVersion];
    if (ver.length == 0) {
        ver = @"—";
    }
    NSString *line2 = [NSString stringWithFormat:@"SDK %@", ver];
    NSString *full = [NSString stringWithFormat:@"%@\n%@", line1, line2];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:full];

    UIColor *primaryColor = [MATDemoTheme primaryTextColor];
    UIColor *secondaryColor = [MATDemoTheme tertiaryTextColor];

    [attr addAttributes:@{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:28],
        NSForegroundColorAttributeName: primaryColor,
    } range:NSMakeRange(0, line1.length)];

    NSUInteger secondStart = line1.length + 1;
    [attr addAttributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:15],
        NSForegroundColorAttributeName: secondaryColor,
    } range:NSMakeRange(secondStart, line2.length)];

    return attr;
}

- (void)buildLayout {
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:stack];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [stack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor constant:-24],
        [stack.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor constant:-32],
    ]];

    [stack addArrangedSubview:[self headerLogoContainer]];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.attributedText = [self headerTitleAttributedString];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    [stack addArrangedSubview:titleLabel];

    UIStackView *sdkCard = [self verticalCardStack];
    [sdkCard addArrangedSubview:[self primaryButton:@"Init SDK" action:@selector(initSDKTapped)]];
    [sdkCard addArrangedSubview:[self secondaryButton:@"Setting" action:@selector(settingTapped)]];
    [stack addArrangedSubview:[self wrapCard:sdkCard]];

    UILabel *sectionTitle = [[UILabel alloc] init];
    sectionTitle.text = @"Advertising Type Testing";
    sectionTitle.font = [UIFont boldSystemFontOfSize:17];
    sectionTitle.textColor = [MATDemoTheme primaryTextColor];
    [stack addArrangedSubview:sectionTitle];

    UIStackView *bannerCard = [self verticalCardStack];
    [bannerCard addArrangedSubview:[self subsectionTitle:@"Banner"]];
    [bannerCard addArrangedSubview:[self primaryButton:@"Load" action:@selector(loadBannerTapped)]];
    self.bannerStatusLabel = [self statusLabel];
    [bannerCard addArrangedSubview:self.bannerStatusLabel];
    self.bannerContainer = [[UIView alloc] init];
    self.bannerContainer.backgroundColor = [UIColor clearColor];
    self.bannerContainer.hidden = YES;
    self.bannerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [bannerCard addArrangedSubview:self.bannerContainer];
    [self.bannerContainer.heightAnchor constraintEqualToConstant:50].active = YES;
    [stack addArrangedSubview:[self wrapCard:bannerCard]];

    UIStackView *interCard = [self verticalCardStack];
    [interCard addArrangedSubview:[self subsectionTitle:@"Interstitial"]];
    UIStackView *interButtons = [[UIStackView alloc] init];
    interButtons.axis = UILayoutConstraintAxisHorizontal;
    interButtons.spacing = 8;
    interButtons.distribution = UIStackViewDistributionFillEqually;
    [interButtons addArrangedSubview:[self primaryButton:@"Load" action:@selector(loadInterstitialTapped)]];
    self.interstitialShowButton = [self secondaryButton:@"Show" action:@selector(showInterstitialTapped)];
    self.interstitialShowButton.enabled = NO;
    [interButtons addArrangedSubview:self.interstitialShowButton];
    [interCard addArrangedSubview:interButtons];
    self.interstitialStatusLabel = [self statusLabel];
    [interCard addArrangedSubview:self.interstitialStatusLabel];
    [stack addArrangedSubview:[self wrapCard:interCard]];

    UIStackView *rewardCard = [self verticalCardStack];
    [rewardCard addArrangedSubview:[self subsectionTitle:@"Reward"]];
    UIStackView *rewardButtons = [[UIStackView alloc] init];
    rewardButtons.axis = UILayoutConstraintAxisHorizontal;
    rewardButtons.spacing = 8;
    rewardButtons.distribution = UIStackViewDistributionFillEqually;
    [rewardButtons addArrangedSubview:[self primaryButton:@"Load" action:@selector(loadRewardTapped)]];
    self.rewardShowButton = [self secondaryButton:@"Show" action:@selector(showRewardTapped)];
    self.rewardShowButton.enabled = NO;
    [rewardButtons addArrangedSubview:self.rewardShowButton];
    [rewardCard addArrangedSubview:rewardButtons];
    self.rewardStatusLabel = [self statusLabel];
    [rewardCard addArrangedSubview:self.rewardStatusLabel];
    [stack addArrangedSubview:[self wrapCard:rewardCard]];

    UIStackView *nativeCard = [self verticalCardStack];
    [nativeCard addArrangedSubview:[self subsectionTitle:@"Native"]];
    UIStackView *nativeButtons = [[UIStackView alloc] init];
    nativeButtons.axis = UILayoutConstraintAxisHorizontal;
    nativeButtons.spacing = 8;
    nativeButtons.distribution = UIStackViewDistributionFillEqually;
    [nativeButtons addArrangedSubview:[self primaryButton:@"Load" action:@selector(loadNativeTapped)]];
    [nativeButtons addArrangedSubview:[self secondaryButton:@"Native List" action:@selector(openNativeListTapped)]];
    [nativeCard addArrangedSubview:nativeButtons];
    self.nativeStatusLabel = [self statusLabel];
    [nativeCard addArrangedSubview:self.nativeStatusLabel];
    [stack addArrangedSubview:[self wrapCard:nativeCard]];

    UILabel *hbSectionTitle = [[UILabel alloc] init];
    hbSectionTitle.text = @"Header Bidding Testing";
    hbSectionTitle.font = [UIFont boldSystemFontOfSize:17];
    hbSectionTitle.textColor = [MATDemoTheme primaryTextColor];
    [stack addArrangedSubview:hbSectionTitle];

    UIStackView *hbInterCard = [self verticalCardStack];
    [hbInterCard addArrangedSubview:[self subsectionTitle:@"Interstitial (Bidding)"]];

    UIStackView *hbInterButtons = [[UIStackView alloc] init];
    hbInterButtons.axis = UILayoutConstraintAxisHorizontal;
    hbInterButtons.spacing = 8;
    hbInterButtons.distribution = UIStackViewDistributionFillEqually;
    [hbInterButtons addArrangedSubview:[self primaryButton:@"Bid + Load" action:@selector(hbBidAndLoadInterstitialTapped)]];
    self.hbInterstitialShowButton = [self secondaryButton:@"Show" action:@selector(hbShowInterstitialTapped)];
    self.hbInterstitialShowButton.enabled = NO;
    [hbInterButtons addArrangedSubview:self.hbInterstitialShowButton];
    [hbInterCard addArrangedSubview:hbInterButtons];
    self.hbInterstitialStatusLabel = [self statusLabel];
    [hbInterCard addArrangedSubview:self.hbInterstitialStatusLabel];
    [stack addArrangedSubview:[self wrapCard:hbInterCard]];

    UIStackView *hbRewardCard = [self verticalCardStack];
    [hbRewardCard addArrangedSubview:[self subsectionTitle:@"Reward (Bidding)"]];
    UIStackView *hbRewardButtons = [[UIStackView alloc] init];
    hbRewardButtons.axis = UILayoutConstraintAxisHorizontal;
    hbRewardButtons.spacing = 8;
    hbRewardButtons.distribution = UIStackViewDistributionFillEqually;
    [hbRewardButtons addArrangedSubview:[self primaryButton:@"Bid + Load" action:@selector(hbBidAndLoadRewardTapped)]];
    self.hbRewardShowButton = [self secondaryButton:@"Show" action:@selector(hbShowRewardTapped)];
    self.hbRewardShowButton.enabled = NO;
    [hbRewardButtons addArrangedSubview:self.hbRewardShowButton];
    [hbRewardCard addArrangedSubview:hbRewardButtons];
    self.hbRewardStatusLabel = [self statusLabel];
    [hbRewardCard addArrangedSubview:self.hbRewardStatusLabel];
    [stack addArrangedSubview:[self wrapCard:hbRewardCard]];

    UIStackView *hbBannerCard = [self verticalCardStack];
    [hbBannerCard addArrangedSubview:[self subsectionTitle:@"Banner (Bidding)"]];
    [hbBannerCard addArrangedSubview:[self primaryButton:@"Bid + Load" action:@selector(hbBidAndLoadBannerTapped)]];
    self.hbBannerStatusLabel = [self statusLabel];
    [hbBannerCard addArrangedSubview:self.hbBannerStatusLabel];
    self.hbBannerContainer = [[UIView alloc] init];
    self.hbBannerContainer.backgroundColor = [UIColor clearColor];
    self.hbBannerContainer.hidden = YES;
    self.hbBannerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [hbBannerCard addArrangedSubview:self.hbBannerContainer];
    [self.hbBannerContainer.heightAnchor constraintEqualToConstant:50].active = YES;
    [stack addArrangedSubview:[self wrapCard:hbBannerCard]];

    UIStackView *hbNativeCard = [self verticalCardStack];
    [hbNativeCard addArrangedSubview:[self subsectionTitle:@"Native (Bidding)"]];
    [hbNativeCard addArrangedSubview:[self primaryButton:@"Bid + Load" action:@selector(hbBidAndLoadNativeTapped)]];
    self.hbNativeStatusLabel = [self statusLabel];
    [hbNativeCard addArrangedSubview:self.hbNativeStatusLabel];
    [stack addArrangedSubview:[self wrapCard:hbNativeCard]];
}

- (UIView *)wrapCard:(UIStackView *)inner {
    UIView *card = [[UIView alloc] init];
    [MATDemoTheme applyCardStyleToView:card cornerRadius:12.0];
    card.layer.masksToBounds = NO;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.06;
    card.layer.shadowRadius = 8.0;
    card.layer.shadowOffset = CGSizeMake(0, 3);
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:inner];
    [NSLayoutConstraint activateConstraints:@[
        [inner.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [inner.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [inner.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [inner.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],
    ]];
    return card;
}

- (UIStackView *)verticalCardStack {
    UIStackView *s = [[UIStackView alloc] init];
    s.axis = UILayoutConstraintAxisVertical;
    s.spacing = 8;
    s.alignment = UIStackViewAlignmentFill;
    return s;
}

- (UILabel *)subsectionTitle:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    l.textColor = [MATDemoTheme primaryTextColor];
    return l;
}

- (UILabel *)statusLabel {
    UILabel *l = [[UILabel alloc] init];
    l.font = [UIFont systemFontOfSize:13];
    l.numberOfLines = 0;
    l.textColor = [MATDemoTheme tertiaryTextColor];
    return l;
}

- (UIButton *)primaryButton:(NSString *)title action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:title forState:UIControlStateNormal];
    [MATDemoTheme applyPrimaryButtonStyle:b];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (UIButton *)secondaryButton:(NSString *)title action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:title forState:UIControlStateNormal];
    [MATDemoTheme applySecondaryButtonStyle:b];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

#pragma mark - Actions

- (void)initSDKTapped {
    __weak typeof(self) weakSelf = self;
    [[MaticooAds shareSDK] initSDK:MAT_DEMO_APP_KEY onSuccess:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf flashMessage:@"SDK Init Success"];
        });
    } onError:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf flashMessage:[NSString stringWithFormat:@"SDK Init Error: %@", error.localizedDescription ?: @"unknown"]];
        });
    }];
}

- (void)settingTapped {
    SettingViewController *setting = [[SettingViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:setting];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)loadBannerTapped {
    if (![[MaticooAds shareSDK] isInitSuccess]) {
        self.bannerStatusLabel.text = @"Please Init SDK first";
        return;
    }
    if (!self.bannerAd) {
        self.bannerAd = [[MATBannerAd alloc] initWithPlacementID:MAT_DEMO_BANNER_PLACEMENT_ID];
        self.bannerAd.canCloseAd = YES;
        self.bannerAd.delegate = self;
    }

    for (UIView *sub in self.bannerContainer.subviews) {
        [sub removeFromSuperview];
    }
    [self.bannerContainer addSubview:self.bannerAd];
    self.bannerAd.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.bannerAd.leadingAnchor constraintEqualToAnchor:self.bannerContainer.leadingAnchor],
        [self.bannerAd.trailingAnchor constraintEqualToAnchor:self.bannerContainer.trailingAnchor],
        [self.bannerAd.topAnchor constraintEqualToAnchor:self.bannerContainer.topAnchor],
        [self.bannerAd.bottomAnchor constraintEqualToAnchor:self.bannerContainer.bottomAnchor],
    ]];

    self.bannerStatusLabel.text = @"loading...";
    self.bannerContainer.hidden = YES;
    [self.bannerAd loadAd];
}

- (void)loadInterstitialTapped {
    if (![[MaticooAds shareSDK] isInitSuccess]) {
        self.interstitialStatusLabel.text = @"Please Init SDK first";
        return;
    }
    if (!self.interstitialAd) {
        self.interstitialAd = [[MATInterstitialAd alloc] initWithPlacementID:MAT_DEMO_INTERSTITIAL_PLACEMENT_ID];
        self.interstitialAd.delegate = self;
    }
    self.interstitialShowButton.enabled = NO;
    self.interstitialStatusLabel.text = @"loading...";
    [self setLoading:YES];
    [self.interstitialAd loadAd];
}

- (void)showInterstitialTapped {
    if (self.interstitialAd.isReady) {
        self.interstitialStatusLabel.text = @"";
        // Waterfall 场景 SDK 忽略 maticooIds 匹配，回传仅作一致性演示
        [self.interstitialAd showAdFromViewController:self maticooIds:self.interstitialIds];
    } else {
        self.interstitialStatusLabel.text = @"not ready";
    }
}

- (void)loadRewardTapped {
    if (![[MaticooAds shareSDK] isInitSuccess]) {
        self.rewardStatusLabel.text = @"Please Init SDK first";
        return;
    }
    if (!self.rewardedVideoAd) {
        self.rewardedVideoAd = [[MATRewardedVideoAd alloc] initWithPlacementID:MAT_DEMO_REWARD_PLACEMENT_ID];
        self.rewardedVideoAd.delegate = self;
    }
    self.rewardShowButton.enabled = NO;
    self.rewardStatusLabel.text = @"loading...";
    [self setLoading:YES];
    [self.rewardedVideoAd loadAd];
}

- (void)showRewardTapped {
    if (self.rewardedVideoAd.isReady) {
        self.rewardStatusLabel.text = @"";
        // Waterfall 场景 SDK 忽略 maticooIds 匹配，回传仅作一致性演示
        [self.rewardedVideoAd showAdFromViewController:self maticooIds:self.rewardIds];
    } else {
        self.rewardStatusLabel.text = @"not ready";
    }
}

#pragma mark - Header Bidding actions

/// 统一询价入口：成功后回调 biddingRequestId（内部已做主线程回跳 + reportTrack 上报）
- (void)hbBidWithPlacementID:(NSString *)placementID
                  completion:(void (^)(NSString *biddingRequestId))completion
                     failure:(void (^)(NSError *error))failure {
    MATBiddingRequestParameter *param = [[MATBiddingRequestParameter alloc] init];
    param.placementId = placementID;
    param.adxId = MAT_DEMO_ADX_ID;
    [MATBiddingRequest biddingRequestWithParameter:param completion:^(MATBiddingResponse * _Nullable bidResponse) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!bidResponse.success) {
                NSError *error = bidResponse.error ?: [NSError errorWithDomain:@"MATDemoErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"unknown bid error"}];
                MATDemoAdLog(@"Bidding", @"bidFailed", @"placement=%@ code=%ld error=%@", placementID, (long)error.code, MATDemoDescribeError(error));
                if (failure) {
                    failure(error);
                }
                return;
            }
            MATDemoAdLog(@"Bidding", @"bidSuccess", @"placement=%@ price=%.4f requestId=%@", placementID, bidResponse.price, bidResponse.biddingRequestId);
            // reportTrack：真实接入应在 AdX 竞价胜出（win）后调用；demo 无 mediation，此处模拟胜出上报
            [MATBiddingRequest reportTrack:bidResponse];
            if (completion) {
                completion(bidResponse.biddingRequestId);
            }
        });
    }];
}

- (void)hbBidAndLoadInterstitialTapped {
    if (![[MaticooAds shareSDK] isInitSuccess]) {
        self.hbInterstitialStatusLabel.text = @"Please Init SDK first";
        return;
    }
    if (!self.hbInterstitialAd) {
        self.hbInterstitialAd = [[MATInterstitialAd alloc] initWithPlacementID:MAT_DEMO_HB_INTERSTITIAL_PLACEMENT_ID];
        self.hbInterstitialAd.delegate = self;
    }
    self.hbInterstitialShowButton.enabled = NO;
    self.hbInterstitialStatusLabel.text = @"bidding...";
    [self hbBidWithPlacementID:MAT_DEMO_HB_INTERSTITIAL_PLACEMENT_ID completion:^(NSString *biddingRequestId) {
        // Bidding 加载：回传询价得到的 requestId
        [self.hbInterstitialAd loadAd:biddingRequestId];
    } failure:^(NSError *error) {
        self.hbInterstitialStatusLabel.text = [NSString stringWithFormat:@"bid failed %@", error.localizedDescription ?: @""];
    }];
}

- (void)hbShowInterstitialTapped {
    // isReadyWithMaticooIds: 与 showAdFromViewController:maticooIds: 同口径：Bidding 按 requestId 精确匹配
    if ([self.hbInterstitialAd isReadyWithMaticooIds:self.hbInterstitialIds]) {
        self.hbInterstitialStatusLabel.text = @"";
        [self.hbInterstitialAd showAdFromViewController:self maticooIds:self.hbInterstitialIds];
    } else {
        self.hbInterstitialStatusLabel.text = @"not ready";
    }
}

- (void)hbBidAndLoadRewardTapped {
    if (![[MaticooAds shareSDK] isInitSuccess]) {
        self.hbRewardStatusLabel.text = @"Please Init SDK first";
        return;
    }
    if (!self.hbRewardedVideoAd) {
        self.hbRewardedVideoAd = [[MATRewardedVideoAd alloc] initWithPlacementID:MAT_DEMO_HB_REWARD_PLACEMENT_ID];
        self.hbRewardedVideoAd.delegate = self;
    }
    self.hbRewardShowButton.enabled = NO;
    self.hbRewardStatusLabel.text = @"bidding...";
    [self hbBidWithPlacementID:MAT_DEMO_HB_REWARD_PLACEMENT_ID completion:^(NSString *biddingRequestId) {
        // Bidding 加载：回传询价得到的 requestId
        [self.hbRewardedVideoAd loadAd:biddingRequestId];
    } failure:^(NSError *error) {
        self.hbRewardStatusLabel.text = [NSString stringWithFormat:@"bid failed %@", error.localizedDescription ?: @""];
    }];
}

- (void)hbShowRewardTapped {
    // isReadyWithMaticooIds: 与 showAdFromViewController:maticooIds: 同口径：Bidding 按 requestId 精确匹配
    if ([self.hbRewardedVideoAd isReadyWithMaticooIds:self.hbRewardIds]) {
        self.hbRewardStatusLabel.text = @"";
        [self.hbRewardedVideoAd showAdFromViewController:self maticooIds:self.hbRewardIds];
    } else {
        self.hbRewardStatusLabel.text = @"not ready";
    }
}

- (void)hbBidAndLoadBannerTapped {
    if (![[MaticooAds shareSDK] isInitSuccess]) {
        self.hbBannerStatusLabel.text = @"Please Init SDK first";
        return;
    }
    if (!self.hbBannerAd) {
        self.hbBannerAd = [[MATBannerAd alloc] initWithPlacementID:MAT_DEMO_HB_BANNER_PLACEMENT_ID];
        self.hbBannerAd.canCloseAd = YES;
        self.hbBannerAd.delegate = self;
    }
    for (UIView *sub in self.hbBannerContainer.subviews) {
        [sub removeFromSuperview];
    }
    [self.hbBannerContainer addSubview:self.hbBannerAd];
    self.hbBannerAd.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.hbBannerAd.leadingAnchor constraintEqualToAnchor:self.hbBannerContainer.leadingAnchor],
        [self.hbBannerAd.trailingAnchor constraintEqualToAnchor:self.hbBannerContainer.trailingAnchor],
        [self.hbBannerAd.topAnchor constraintEqualToAnchor:self.hbBannerContainer.topAnchor],
        [self.hbBannerAd.bottomAnchor constraintEqualToAnchor:self.hbBannerContainer.bottomAnchor],
    ]];

    self.hbBannerStatusLabel.text = @"bidding...";
    self.hbBannerContainer.hidden = YES;
    [self hbBidWithPlacementID:MAT_DEMO_HB_BANNER_PLACEMENT_ID completion:^(NSString *biddingRequestId) {
        // Bidding 加载：回传询价得到的 requestId
        [self.hbBannerAd loadAd:biddingRequestId];
    } failure:^(NSError *error) {
        self.hbBannerStatusLabel.text = [NSString stringWithFormat:@"bid failed %@", error.localizedDescription ?: @""];
    }];
}

- (void)hbBidAndLoadNativeTapped {
    if (![[MaticooAds shareSDK] isInitSuccess]) {
        self.hbNativeStatusLabel.text = @"Please Init SDK first";
        return;
    }
    if (!self.hbNativeAd) {
        self.hbNativeAd = [[MATNativeAd alloc] initWithPlacementID:MAT_DEMO_HB_NATIVE_PLACEMENT_ID];
        self.hbNativeAd.delegate = self;
        [MATNativeAdRenderer configureNativeAd:self.hbNativeAd];
    }
    self.hbNativeStatusLabel.text = @"bidding...";
    [self hbBidWithPlacementID:MAT_DEMO_HB_NATIVE_PLACEMENT_ID completion:^(NSString *biddingRequestId) {
        // Bidding 加载：回传询价得到的 requestId
        [self.hbNativeAd loadAd:biddingRequestId];
    } failure:^(NSError *error) {
        self.hbNativeStatusLabel.text = [NSString stringWithFormat:@"bid failed %@", error.localizedDescription ?: @""];
    }];
}

- (void)destroyNativeAd {
    [MATNativeAdPresenter dismissAnimated:NO];
    if (self.nativeAd) {
        [self.nativeAd destroy];
        self.nativeAd = nil;
    }
}

- (void)loadNativeTapped {
    if (![[MaticooAds shareSDK] isInitSuccess]) {
        self.nativeStatusLabel.text = @"Please Init SDK first";
        return;
    }

    [self destroyNativeAd];
    self.nativeStatusLabel.text = @"loading...";

    MATNativeAd *ad = [[MATNativeAd alloc] initWithPlacementID:MAT_DEMO_NATIVE_PLACEMENT_ID];
    ad.delegate = self;
    self.nativeAd = ad;
    [MATNativeAdRenderer configureNativeAd:ad];
    [ad loadAd];
}

- (void)openNativeListTapped {
    if (![[MaticooAds shareSDK] isInitSuccess]) {
        [self flashMessage:@"Please Init SDK first"];
        return;
    }
    NativeListViewController *listVC = [[NativeListViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:listVC];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - Loading / toast

- (void)setLoading:(BOOL)on {
    if (on) {
        if (!self.loadingOverlay) {
            UIView *v = [[UIView alloc] initWithFrame:self.view.bounds];
            v.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
            v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            indicator.translatesAutoresizingMaskIntoConstraints = NO;
            [v addSubview:indicator];
            [NSLayoutConstraint activateConstraints:@[
                [indicator.centerXAnchor constraintEqualToAnchor:v.centerXAnchor],
                [indicator.centerYAnchor constraintEqualToAnchor:v.centerYAnchor],
            ]];
            [indicator startAnimating];
            self.loadingOverlay = v;
        }
        self.loadingOverlay.frame = self.view.bounds;
        [self.view addSubview:self.loadingOverlay];
    } else {
        [self.loadingOverlay removeFromSuperview];
    }
}

- (void)flashMessage:(NSString *)msg {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:ac animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ac dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

#pragma mark - MATBannerAdDelegate

- (void)bannerAdDidLoad:(MATBannerAd *)bannerAd {
    MATDemoAdLog(@"Banner", @"didLoad", @"placement=%@", bannerAd.placementID ?: @"?");
    if (bannerAd == self.hbBannerAd) {
        self.hbBannerStatusLabel.text = @"bid load success";
        self.hbBannerContainer.hidden = NO;
        return;
    }
    self.bannerStatusLabel.text = @"load success";
    self.bannerContainer.hidden = NO;
}

- (void)bannerAd:(MATBannerAd *)bannerAd didFailWithError:(NSError *)error {
    MATDemoAdLog(@"Banner", @"didFailWithError", @"placement=%@ error=%@", bannerAd.placementID ?: @"?", MATDemoDescribeError(error));
    if (bannerAd == self.hbBannerAd) {
        self.hbBannerStatusLabel.text = [NSString stringWithFormat:@"bid load failed %@", error.localizedDescription ?: @""];
        return;
    }
    self.bannerStatusLabel.text = [NSString stringWithFormat:@"load failed %@", error.localizedDescription ?: @""];
}

- (void)bannerAdDidImpression:(MATBannerAd *)bannerAd {
    MATDemoAdLog(@"Banner", @"didImpression", @"placement=%@", bannerAd.placementID ?: @"?");
}

- (void)bannerAd:(MATBannerAd *)bannerAd showFailWithError:(NSError *)error {
    MATDemoAdLog(@"Banner", @"showFailWithError", @"placement=%@ error=%@", bannerAd.placementID ?: @"?", MATDemoDescribeError(error));
}

- (void)bannerAdDidClick:(MATBannerAd *)bannerAd {
    MATDemoAdLog(@"Banner", @"didClick", @"placement=%@", bannerAd.placementID ?: @"?");
}

- (void)bannerAdDismissed:(MATBannerAd *)bannerAd {
    MATDemoAdLog(@"Banner", @"dismissed", @"placement=%@", bannerAd.placementID ?: @"?");
    if (bannerAd == self.hbBannerAd) {
        self.hbBannerContainer.hidden = YES;
        self.hbBannerStatusLabel.text = @"";
    }
}

#pragma mark - MATInterstitialAdDelegate

- (BOOL)isHBInterstitialAd:(MATInterstitialAd *)ad {
    return ad == self.hbInterstitialAd;
}

- (NSString *)hbInterstitialPidForAd:(MATInterstitialAd *)ad {
    return [self isHBInterstitialAd:ad] ? MAT_DEMO_HB_INTERSTITIAL_PLACEMENT_ID : MAT_DEMO_INTERSTITIAL_PLACEMENT_ID;
}

/// 新回调（SDK 新优先：实现本方法后旧 didLoad 不再回调）。
/// HB：持有 maticooIds 供精确 show；Waterfall：biddingRequestId 为空，show 时回传 SDK 忽略匹配。
- (void)interstitialAdDidLoad:(MATInterstitialAd *)interstitialAd maticooIds:(MATMaticooIds *)maticooIds {
    if ([self isHBInterstitialAd:interstitialAd]) {
        self.hbInterstitialIds = maticooIds;
        self.hbInterstitialShowButton.enabled = YES;
        self.hbInterstitialStatusLabel.text = @"bid load success";
        MATDemoAdLog(@"Bidding", @"didLoad", @"placement=%@ requestId=%@", MAT_DEMO_HB_INTERSTITIAL_PLACEMENT_ID, maticooIds.biddingRequestId ?: @"(waterfall)");
        return;
    }
    self.interstitialIds = maticooIds;
    MATDemoAdLog(@"Interstitial", @"didLoad", @"placement=%@", MAT_DEMO_INTERSTITIAL_PLACEMENT_ID);
    [self setLoading:NO];
    self.interstitialShowButton.enabled = YES;
    self.interstitialStatusLabel.text = @"load success";
}

/// 旧回调保留仅为满足协议必选；SDK 已实现新回调时不会走到这里
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)interstitialAdDidLoad:(MATInterstitialAd *)interstitialAd {
    MATDemoAdLog(@"Interstitial", @"didLoad(legacy)", @"unreachable: new callback takes priority");
}
#pragma clang diagnostic pop

- (void)interstitialAd:(MATInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    if ([self isHBInterstitialAd:interstitialAd]) {
        MATDemoAdLog(@"Bidding", @"didFailWithError", @"placement=%@ error=%@", MAT_DEMO_HB_INTERSTITIAL_PLACEMENT_ID, MATDemoDescribeError(error));
        self.hbInterstitialStatusLabel.text = [NSString stringWithFormat:@"bid load failed %@", error.localizedDescription ?: @""];
        return;
    }
    MATDemoAdLog(@"Interstitial", @"didFailWithError", @"placement=%@ error=%@", MAT_DEMO_INTERSTITIAL_PLACEMENT_ID, MATDemoDescribeError(error));
    [self setLoading:NO];
    self.interstitialStatusLabel.text = [NSString stringWithFormat:@"load failed %@", error.localizedDescription ?: @""];
}

- (void)interstitialAd:(MATInterstitialAd *)interstitialAd displayFailWithError:(NSError *)error {
    if ([self isHBInterstitialAd:interstitialAd]) {
        MATDemoAdLog(@"Bidding", @"displayFailWithError", @"placement=%@ error=%@", MAT_DEMO_HB_INTERSTITIAL_PLACEMENT_ID, MATDemoDescribeError(error));
        self.hbInterstitialStatusLabel.text = [NSString stringWithFormat:@"show failed %@", error.localizedDescription ?: @""];
        return;
    }
    MATDemoAdLog(@"Interstitial", @"displayFailWithError", @"placement=%@ error=%@", MAT_DEMO_INTERSTITIAL_PLACEMENT_ID, MATDemoDescribeError(error));
    self.interstitialStatusLabel.text = [NSString stringWithFormat:@"show failed %@", error.localizedDescription ?: @""];
}

- (void)interstitialAdWillLogImpression:(MATInterstitialAd *)interstitialAd {
    MATDemoAdLog([self isHBInterstitialAd:interstitialAd] ? @"Bidding" : @"Interstitial", @"willLogImpression", @"placement=%@", [self hbInterstitialPidForAd:interstitialAd]);
}

- (void)interstitialAdDidClick:(MATInterstitialAd *)interstitialAd {
    MATDemoAdLog([self isHBInterstitialAd:interstitialAd] ? @"Bidding" : @"Interstitial", @"didClick", @"placement=%@", [self hbInterstitialPidForAd:interstitialAd]);
}

- (void)interstitialAdWillClose:(MATInterstitialAd *)interstitialAd {
    MATDemoAdLog([self isHBInterstitialAd:interstitialAd] ? @"Bidding" : @"Interstitial", @"willClose", @"placement=%@", [self hbInterstitialPidForAd:interstitialAd]);
}

- (void)interstitialAdDidClose:(MATInterstitialAd *)interstitialAd {
    MATDemoAdLog([self isHBInterstitialAd:interstitialAd] ? @"Bidding" : @"Interstitial", @"didClose", @"placement=%@", [self hbInterstitialPidForAd:interstitialAd]);
    if ([self isHBInterstitialAd:interstitialAd]) {
        self.hbInterstitialStatusLabel.text = @"";
        self.hbInterstitialShowButton.enabled = NO;
        self.hbInterstitialIds = nil;
    } else {
        self.interstitialStatusLabel.text = @"";
    }
}

- (void)interstitialAdEndCardShow:(MATInterstitialAd *)interstitialAd {
    MATDemoAdLog([self isHBInterstitialAd:interstitialAd] ? @"Bidding" : @"Interstitial", @"endCardShow", @"placement=%@", [self hbInterstitialPidForAd:interstitialAd]);
}

#pragma mark - MATRewardedVideoAdDelegate

- (BOOL)isHBRewardAd:(MATRewardedVideoAd *)ad {
    return ad == self.hbRewardedVideoAd;
}

- (NSString *)hbRewardPidForAd:(MATRewardedVideoAd *)ad {
    return [self isHBRewardAd:ad] ? MAT_DEMO_HB_REWARD_PLACEMENT_ID : MAT_DEMO_REWARD_PLACEMENT_ID;
}

/// 新回调（SDK 新优先：实现本方法后旧 didLoad 不再回调）。
/// HB：持有 maticooIds 供精确 show；Waterfall：biddingRequestId 为空，show 时回传 SDK 忽略匹配。
- (void)rewardedVideoAdDidLoad:(MATRewardedVideoAd *)rewardedVideoAd maticooIds:(MATMaticooIds *)maticooIds {
    if ([self isHBRewardAd:rewardedVideoAd]) {
        self.hbRewardIds = maticooIds;
        self.hbRewardShowButton.enabled = YES;
        self.hbRewardStatusLabel.text = @"bid load success";
        MATDemoAdLog(@"Bidding", @"didLoad", @"placement=%@ requestId=%@", MAT_DEMO_HB_REWARD_PLACEMENT_ID, maticooIds.biddingRequestId ?: @"(waterfall)");
        return;
    }
    self.rewardIds = maticooIds;
    MATDemoAdLog(@"Rewarded", @"didLoad", @"placement=%@", MAT_DEMO_REWARD_PLACEMENT_ID);
    [self setLoading:NO];
    self.rewardShowButton.enabled = YES;
    self.rewardStatusLabel.text = @"load success";
}

/// 旧回调保留仅为满足协议必选；SDK 已实现新回调时不会走到这里
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)rewardedVideoAdDidLoad:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog(@"Rewarded", @"didLoad(legacy)", @"unreachable: new callback takes priority");
}
#pragma clang diagnostic pop

- (void)rewardedVideoAd:(MATRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    if ([self isHBRewardAd:rewardedVideoAd]) {
        MATDemoAdLog(@"Bidding", @"didFailWithError", @"placement=%@ error=%@", MAT_DEMO_HB_REWARD_PLACEMENT_ID, MATDemoDescribeError(error));
        self.hbRewardStatusLabel.text = [NSString stringWithFormat:@"bid load failed %@", error.localizedDescription ?: @""];
        return;
    }
    MATDemoAdLog(@"Rewarded", @"didFailWithError", @"placement=%@ error=%@", MAT_DEMO_REWARD_PLACEMENT_ID, MATDemoDescribeError(error));
    [self setLoading:NO];
    self.rewardStatusLabel.text = [NSString stringWithFormat:@"load failed %@", error.localizedDescription ?: @""];
}

- (void)rewardedVideoAd:(MATRewardedVideoAd *)rewardedVideoAd displayFailWithError:(NSError *)error {
    if ([self isHBRewardAd:rewardedVideoAd]) {
        MATDemoAdLog(@"Bidding", @"displayFailWithError", @"placement=%@ error=%@", MAT_DEMO_HB_REWARD_PLACEMENT_ID, MATDemoDescribeError(error));
        self.hbRewardStatusLabel.text = [NSString stringWithFormat:@"show failed %@", error.localizedDescription ?: @""];
        return;
    }
    MATDemoAdLog(@"Rewarded", @"displayFailWithError", @"placement=%@ error=%@", MAT_DEMO_REWARD_PLACEMENT_ID, MATDemoDescribeError(error));
    self.rewardStatusLabel.text = [NSString stringWithFormat:@"show failed %@", error.localizedDescription ?: @""];
}

- (void)rewardedVideoAdStarted:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog([self isHBRewardAd:rewardedVideoAd] ? @"Bidding" : @"Rewarded", @"started", @"placement=%@", [self hbRewardPidForAd:rewardedVideoAd]);
}

- (void)rewardedVideoAdCompleted:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog([self isHBRewardAd:rewardedVideoAd] ? @"Bidding" : @"Rewarded", @"completed", @"placement=%@", [self hbRewardPidForAd:rewardedVideoAd]);
}

- (void)rewardedVideoAdWillLogImpression:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog([self isHBRewardAd:rewardedVideoAd] ? @"Bidding" : @"Rewarded", @"willLogImpression", @"placement=%@", [self hbRewardPidForAd:rewardedVideoAd]);
}

- (void)rewardedVideoAdDidClick:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog([self isHBRewardAd:rewardedVideoAd] ? @"Bidding" : @"Rewarded", @"didClick", @"placement=%@", [self hbRewardPidForAd:rewardedVideoAd]);
}

- (void)rewardedVideoAdWillClose:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog([self isHBRewardAd:rewardedVideoAd] ? @"Bidding" : @"Rewarded", @"willClose", @"placement=%@", [self hbRewardPidForAd:rewardedVideoAd]);
}

- (void)rewardedVideoAdDidClose:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog([self isHBRewardAd:rewardedVideoAd] ? @"Bidding" : @"Rewarded", @"didClose", @"placement=%@", [self hbRewardPidForAd:rewardedVideoAd]);
    if ([self isHBRewardAd:rewardedVideoAd]) {
        self.hbRewardStatusLabel.text = @"";
        self.hbRewardShowButton.enabled = NO;
        self.hbRewardIds = nil;
    } else {
        self.rewardStatusLabel.text = @"";
    }
}

- (void)rewardedVideoAdReward:(MATRewardedVideoAd *)rewardedVideoAd rewardInfo:(MATRewardInfo *)rewardInfo {
    MATDemoAdLog([self isHBRewardAd:rewardedVideoAd] ? @"Bidding" : @"Rewarded", @"didReward", @"placement=%@ rewardId=%@ name=%@ amount=%ld",
                 [self hbRewardPidForAd:rewardedVideoAd],
                 rewardInfo.rewardId ?: @"—",
                 rewardInfo.rewardName ?: @"—",
                 (long)rewardInfo.rewardAmount);
}

- (void)rewardedVideoAdDidSkip:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog([self isHBRewardAd:rewardedVideoAd] ? @"Bidding" : @"Rewarded", @"didSkip", @"placement=%@", [self hbRewardPidForAd:rewardedVideoAd]);
}

- (void)rewardedVideoAdEndCardShow:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog([self isHBRewardAd:rewardedVideoAd] ? @"Bidding" : @"Rewarded", @"endCardShow", @"placement=%@", [self hbRewardPidForAd:rewardedVideoAd]);
}

#pragma mark - MATNativeAdDelegate

- (void)nativeAdLoadSuccess:(MATNativeAd *)nativeAd {
    MATDemoAdLog(@"Native", @"didLoad", @"placement=%@", nativeAd.placementID ?: @"?");
    if (nativeAd == self.hbNativeAd) {
        self.hbNativeStatusLabel.text = @"bid load success";
        __weak typeof(self) weakSelf = self;
        [MATNativeAdPresenter presentNativeAd:nativeAd fromViewController:self onDismiss:^{
            weakSelf.hbNativeStatusLabel.text = @"";
            if (weakSelf.hbNativeAd) {
                [weakSelf.hbNativeAd destroy];
                weakSelf.hbNativeAd = nil;
            }
        }];
        return;
    }
    self.nativeStatusLabel.text = @"load success";
    [self flashMessage:@"Native load success"];

    __weak typeof(self) weakSelf = self;
    [MATNativeAdPresenter presentNativeAd:nativeAd fromViewController:self onDismiss:^{
        weakSelf.nativeStatusLabel.text = @"";
        if (weakSelf.nativeAd) {
            [weakSelf.nativeAd destroy];
            weakSelf.nativeAd = nil;
        }
    }];
}

- (void)nativeAdFailed:(MATNativeAd *)nativeAd withError:(NSError *)error {
    MATDemoAdLog(@"Native", @"didFailWithError", @"placement=%@ error=%@", nativeAd.placementID ?: @"?", MATDemoDescribeError(error));
    if (nativeAd == self.hbNativeAd) {
        self.hbNativeStatusLabel.text = [NSString stringWithFormat:@"bid load failed %@", error.localizedDescription ?: @""];
        return;
    }
    self.nativeStatusLabel.text = [NSString stringWithFormat:@"load failed %@", error.localizedDescription ?: @""];
    [self flashMessage:@"Native load failed"];
}

- (void)nativeAdDisplayed:(MATNativeAd *)nativeAd {
    MATDemoAdLog(@"Native", @"didDisplay", @"placement=%@", nativeAd.placementID ?: @"?");
}

- (void)nativeAd:(MATNativeAd *)nativeAd displayFailWithError:(NSError *)error {
    MATDemoAdLog(@"Native", @"displayFailWithError", @"placement=%@ error=%@", nativeAd.placementID ?: @"?", MATDemoDescribeError(error));
    self.nativeStatusLabel.text = [NSString stringWithFormat:@"show failed %@", error.localizedDescription ?: @""];
    [self flashMessage:@"Native show failed"];
}

- (void)nativeAdClicked:(MATNativeAd *)nativeAd {
    MATDemoAdLog(@"Native", @"didClick", @"placement=%@", nativeAd.placementID ?: @"?");
    [self flashMessage:@"Native clicked"];
}

@end
