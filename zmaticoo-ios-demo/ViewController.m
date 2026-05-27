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
    [MATInterstitialAd destroy:@[MAT_DEMO_INTERSTITIAL_PLACEMENT_ID]];
    [MATRewardedVideoAd destroy:@[MAT_DEMO_REWARD_PLACEMENT_ID]];
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
        [self.interstitialAd showAdFromViewController:self];
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
        [self.rewardedVideoAd showAdFromViewController:self];
    } else {
        self.rewardStatusLabel.text = @"not ready";
    }
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
    self.bannerStatusLabel.text = @"load success";
    self.bannerContainer.hidden = NO;
}

- (void)bannerAd:(MATBannerAd *)bannerAd didFailWithError:(NSError *)error {
    MATDemoAdLog(@"Banner", @"didFailWithError", @"placement=%@ error=%@", bannerAd.placementID ?: @"?", MATDemoDescribeError(error));
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
}

#pragma mark - MATInterstitialAdDelegate

- (void)interstitialAdDidLoad:(MATInterstitialAd *)interstitialAd {
    MATDemoAdLog(@"Interstitial", @"didLoad", @"placement=%@", MAT_DEMO_INTERSTITIAL_PLACEMENT_ID);
    [self setLoading:NO];
    self.interstitialShowButton.enabled = YES;
    self.interstitialStatusLabel.text = @"load success";
}

- (void)interstitialAd:(MATInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    MATDemoAdLog(@"Interstitial", @"didFailWithError", @"placement=%@ error=%@", MAT_DEMO_INTERSTITIAL_PLACEMENT_ID, MATDemoDescribeError(error));
    [self setLoading:NO];
    self.interstitialStatusLabel.text = [NSString stringWithFormat:@"load failed %@", error.localizedDescription ?: @""];
}

- (void)interstitialAd:(MATInterstitialAd *)interstitialAd displayFailWithError:(NSError *)error {
    MATDemoAdLog(@"Interstitial", @"displayFailWithError", @"placement=%@ error=%@", MAT_DEMO_INTERSTITIAL_PLACEMENT_ID, MATDemoDescribeError(error));
    self.interstitialStatusLabel.text = [NSString stringWithFormat:@"show failed %@", error.localizedDescription ?: @""];
}

- (void)interstitialAdWillLogImpression:(MATInterstitialAd *)interstitialAd {
    MATDemoAdLog(@"Interstitial", @"willLogImpression", @"placement=%@", MAT_DEMO_INTERSTITIAL_PLACEMENT_ID);
}

- (void)interstitialAdDidClick:(MATInterstitialAd *)interstitialAd {
    MATDemoAdLog(@"Interstitial", @"didClick", @"placement=%@", MAT_DEMO_INTERSTITIAL_PLACEMENT_ID);
}

- (void)interstitialAdWillClose:(MATInterstitialAd *)interstitialAd {
    MATDemoAdLog(@"Interstitial", @"willClose", @"placement=%@", MAT_DEMO_INTERSTITIAL_PLACEMENT_ID);
}

- (void)interstitialAdDidClose:(MATInterstitialAd *)interstitialAd {
    MATDemoAdLog(@"Interstitial", @"didClose", @"placement=%@", MAT_DEMO_INTERSTITIAL_PLACEMENT_ID);
    self.interstitialStatusLabel.text = @"";
}

- (void)interstitialAdEndCardShow:(MATInterstitialAd *)interstitialAd {
    MATDemoAdLog(@"Interstitial", @"endCardShow", @"placement=%@", MAT_DEMO_INTERSTITIAL_PLACEMENT_ID);
}

#pragma mark - MATRewardedVideoAdDelegate

- (void)rewardedVideoAdDidLoad:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog(@"Rewarded", @"didLoad", @"placement=%@", MAT_DEMO_REWARD_PLACEMENT_ID);
    [self setLoading:NO];
    self.rewardShowButton.enabled = YES;
    self.rewardStatusLabel.text = @"load success";
}

- (void)rewardedVideoAd:(MATRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    MATDemoAdLog(@"Rewarded", @"didFailWithError", @"placement=%@ error=%@", MAT_DEMO_REWARD_PLACEMENT_ID, MATDemoDescribeError(error));
    [self setLoading:NO];
    self.rewardStatusLabel.text = [NSString stringWithFormat:@"load failed %@", error.localizedDescription ?: @""];
}

- (void)rewardedVideoAd:(MATRewardedVideoAd *)rewardedVideoAd displayFailWithError:(NSError *)error {
    MATDemoAdLog(@"Rewarded", @"displayFailWithError", @"placement=%@ error=%@", MAT_DEMO_REWARD_PLACEMENT_ID, MATDemoDescribeError(error));
    self.rewardStatusLabel.text = [NSString stringWithFormat:@"show failed %@", error.localizedDescription ?: @""];
}

- (void)rewardedVideoAdStarted:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog(@"Rewarded", @"started", @"placement=%@", MAT_DEMO_REWARD_PLACEMENT_ID);
}

- (void)rewardedVideoAdCompleted:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog(@"Rewarded", @"completed", @"placement=%@", MAT_DEMO_REWARD_PLACEMENT_ID);
}

- (void)rewardedVideoAdWillLogImpression:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog(@"Rewarded", @"willLogImpression", @"placement=%@", MAT_DEMO_REWARD_PLACEMENT_ID);
}

- (void)rewardedVideoAdDidClick:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog(@"Rewarded", @"didClick", @"placement=%@", MAT_DEMO_REWARD_PLACEMENT_ID);
}

- (void)rewardedVideoAdWillClose:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog(@"Rewarded", @"willClose", @"placement=%@", MAT_DEMO_REWARD_PLACEMENT_ID);
}

- (void)rewardedVideoAdDidClose:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog(@"Rewarded", @"didClose", @"placement=%@", MAT_DEMO_REWARD_PLACEMENT_ID);
    self.rewardStatusLabel.text = @"";
}

- (void)rewardedVideoAdReward:(MATRewardedVideoAd *)rewardedVideoAd rewardInfo:(MATRewardInfo *)rewardInfo {
    MATDemoAdLog(@"Rewarded", @"didReward", @"placement=%@ rewardId=%@ name=%@ amount=%ld",
                 MAT_DEMO_REWARD_PLACEMENT_ID,
                 rewardInfo.rewardId ?: @"—",
                 rewardInfo.rewardName ?: @"—",
                 (long)rewardInfo.rewardAmount);
}

- (void)rewardedVideoAdDidSkip:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog(@"Rewarded", @"didSkip", @"placement=%@", MAT_DEMO_REWARD_PLACEMENT_ID);
}

- (void)rewardedVideoAdEndCardShow:(MATRewardedVideoAd *)rewardedVideoAd {
    MATDemoAdLog(@"Rewarded", @"endCardShow", @"placement=%@", MAT_DEMO_REWARD_PLACEMENT_ID);
}

#pragma mark - MATNativeAdDelegate

- (void)nativeAdLoadSuccess:(MATNativeAd *)nativeAd {
    MATDemoAdLog(@"Native", @"didLoad", @"placement=%@", nativeAd.placementID ?: @"?");
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
