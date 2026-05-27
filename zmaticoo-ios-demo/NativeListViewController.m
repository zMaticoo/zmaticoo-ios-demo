//
//  NativeListViewController.m
//  zmaticoo-ios-demo
//

#import "NativeListViewController.h"
#import "MATDemoConfig.h"
#import "MATDemoLog.h"
#import "MATDemoTheme.h"
#import "MATNativeAdRenderer.h"
#import <MaticooSDK/MaticooSDK.h>

static const NSInteger kInitialNormalItemCount = 54;
static const NSInteger kPageNormalItemCount = 54;
static const NSInteger kMaxNormalItemCount = 200;
static const NSInteger kAdEveryNNormalItems = 9;
static const CGFloat kNormalRowHeight = 68.0;
static const CGFloat kAdLoadingRowHeight = 84.0;

static const NSInteger kCellTypeNormal = 0;
static const NSInteger kCellTypeAd = 1;

#pragma mark - NativeListNormalCell

@interface NativeListNormalCell : UITableViewCell
@property (nonatomic, strong) UILabel *indexLabel;
@end

@implementation NativeListNormalCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        UIView *card = [[UIView alloc] init];
        [MATDemoTheme applyCardStyleToView:card cornerRadius:12.0];
        card.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:card];

        _indexLabel = [[UILabel alloc] init];
        _indexLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        _indexLabel.textAlignment = NSTextAlignmentCenter;
        _indexLabel.textColor = [MATDemoTheme primaryTextColor];
        _indexLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:_indexLabel];

        [NSLayoutConstraint activateConstraints:@[
            [card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6],
            [card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6],
            [card.heightAnchor constraintGreaterThanOrEqualToConstant:56],
            [_indexLabel.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
            [_indexLabel.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        ]];
    }
    return self;
}

@end

#pragma mark - NativeListAdSlot

@interface NativeListAdSlot : NSObject
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, strong, nullable) MATNativeAd *nativeAd;
@property (nonatomic, strong) UIView *adShellHost;
@property (nonatomic, assign) BOOL adLoadRequested;
@property (nonatomic, assign) BOOL loadFailed;
@property (nonatomic, assign) BOOL hasRendered;
@property (nonatomic, assign) CGFloat cardHeight;
@property (nonatomic, copy, nullable) NSString *errorMessage;
@end

@implementation NativeListAdSlot

- (instancetype)init {
    self = [super init];
    if (self) {
        _adShellHost = [[UIView alloc] init];
        _adShellHost.translatesAutoresizingMaskIntoConstraints = NO;
        _cardHeight = 72.0;
    }
    return self;
}

- (void)destroyAd {
    if (self.nativeAd) {
        [self.nativeAd destroy];
        self.nativeAd = nil;
    }
    for (UIView *sub in self.adShellHost.subviews) {
        [sub removeFromSuperview];
    }
    self.adLoadRequested = NO;
    self.loadFailed = NO;
    self.hasRendered = NO;
    self.cardHeight = 72.0;
    self.errorMessage = nil;
}

@end

#pragma mark - NativeListAdCell

@interface NativeListAdCell : UITableViewCell
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIView *adContainer;
@property (nonatomic, assign) BOOL didMountShellHost;
- (void)bindAdShellHost:(UIView *)shellHost
               nativeAd:(nullable MATNativeAd *)nativeAd
              loadFailed:(BOOL)loadFailed
             errorMessage:(nullable NSString *)errorMessage
               hasRendered:(BOOL)hasRendered;
@end

@implementation NativeListAdCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        UIView *card = [[UIView alloc] init];
        [MATDemoTheme applyCardStyleToView:card cornerRadius:12.0];
        card.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:card];

        _adContainer = [[UIView alloc] init];
        _adContainer.translatesAutoresizingMaskIntoConstraints = NO;
        _adContainer.clipsToBounds = YES;

        _placeholderLabel = [[UILabel alloc] init];
        _placeholderLabel.text = @"Loading native ad...";
        _placeholderLabel.font = [UIFont systemFontOfSize:13];
        _placeholderLabel.textAlignment = NSTextAlignmentCenter;
        _placeholderLabel.numberOfLines = 0;
        _placeholderLabel.textColor = [MATDemoTheme tertiaryTextColor];
        _placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;

        [card addSubview:_adContainer];
        [_adContainer addSubview:_placeholderLabel];

        [NSLayoutConstraint activateConstraints:@[
            [card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6],
            [card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6],

            [_adContainer.topAnchor constraintEqualToAnchor:card.topAnchor constant:8],
            [_adContainer.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:8],
            [_adContainer.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-8],
            [_adContainer.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-8],

            [_placeholderLabel.centerXAnchor constraintEqualToAnchor:_adContainer.centerXAnchor],
            [_placeholderLabel.centerYAnchor constraintEqualToAnchor:_adContainer.centerYAnchor],
            [_placeholderLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:_adContainer.leadingAnchor constant:8],
            [_placeholderLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_adContainer.trailingAnchor constant:-8],
        ]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    // MATNativeAd 无 unregister：广告行独占 reuseIdentifier；渲染视图由数据源持有，回收时不移除。
    self.placeholderLabel.hidden = NO;
    self.placeholderLabel.text = @"Loading native ad...";
}

- (void)bindAdShellHost:(UIView *)shellHost
               nativeAd:(MATNativeAd *)nativeAd
              loadFailed:(BOOL)loadFailed
             errorMessage:(NSString *)errorMessage
              hasRendered:(BOOL)hasRendered {
    if (loadFailed) {
        self.placeholderLabel.hidden = NO;
        self.placeholderLabel.text = errorMessage.length > 0 ? errorMessage : @"Native ad load failed";
        return;
    }

    if (!hasRendered || !nativeAd || !nativeAd.nativeElements) {
        self.placeholderLabel.hidden = NO;
        self.placeholderLabel.text = @"Loading native ad...";
        return;
    }

    if (shellHost.superview != self.adContainer) {
        [shellHost removeFromSuperview];
        shellHost.translatesAutoresizingMaskIntoConstraints = NO;
        [self.adContainer addSubview:shellHost];
        [NSLayoutConstraint activateConstraints:@[
            [shellHost.topAnchor constraintEqualToAnchor:self.adContainer.topAnchor],
            [shellHost.leadingAnchor constraintEqualToAnchor:self.adContainer.leadingAnchor],
            [shellHost.trailingAnchor constraintEqualToAnchor:self.adContainer.trailingAnchor],
            [shellHost.bottomAnchor constraintEqualToAnchor:self.adContainer.bottomAnchor],
        ]];
        self.didMountShellHost = YES;
    }

    self.placeholderLabel.hidden = YES;
}

@end

#pragma mark - NativeListViewController

@interface NativeListViewController () <UITableViewDataSource, UITableViewDelegate, MATNativeAdDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NativeListAdSlot *> *adSlots;
@property (nonatomic, assign) NSInteger normalItemCount;
@property (nonatomic, assign) BOOL isLoadingMore;
@end

@implementation NativeListViewController

- (void)dealloc {
    [self destroyAllAdSlots];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [MATDemoTheme groupedBackgroundColor];
    self.normalItemCount = kInitialNormalItemCount;
    self.adSlots = [NSMutableDictionary dictionary];

    self.title = @"Native List";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(backTapped)];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.estimatedRowHeight = 380.0;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView registerClass:[NativeListNormalCell class] forCellReuseIdentifier:@"NormalCell"];
    [self registerAdCellReuseIdentifiers];
    [self.view addSubview:self.tableView];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshList) forControlEvents:UIControlEventValueChanged];
    if (@available(iOS 10.0, *)) {
        self.tableView.refreshControl = self.refreshControl;
    } else {
        [self.tableView addSubview:self.refreshControl];
    }

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],
        [self.tableView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],
        [self.tableView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
        [self.tableView.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
    ]];
}

- (void)backTapped {
    if (self.navigationController.presentingViewController) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)groupsCount {
    return self.normalItemCount / kAdEveryNNormalItems;
}

- (NSInteger)totalItemCount {
    NSInteger groups = [self groupsCount];
    NSInteger remaining = self.normalItemCount % kAdEveryNNormalItems;
    return groups * (kAdEveryNNormalItems + 1) + remaining;
}

- (NSInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath {
    return [self cellTypeForRow:indexPath.row];
}

- (NSInteger)cellTypeForRow:(NSInteger)row {
    NSInteger adEveryCycle = kAdEveryNNormalItems + 1;
    NSInteger groups = [self groupsCount];
    NSInteger groupsItems = groups * adEveryCycle;
    if (row >= groupsItems) {
        return kCellTypeNormal;
    }
    NSInteger within = row % adEveryCycle;
    return within == kAdEveryNNormalItems ? kCellTypeAd : kCellTypeNormal;
}

- (NSInteger)normalIndexForRow:(NSInteger)row {
    NSInteger adEveryCycle = kAdEveryNNormalItems + 1;
    NSInteger groups = [self groupsCount];
    NSInteger groupsItems = groups * adEveryCycle;
    if (row < groupsItems) {
        NSInteger cycleIndex = row / adEveryCycle;
        NSInteger within = row % adEveryCycle;
        return cycleIndex * kAdEveryNNormalItems + within;
    }
    return groups * kAdEveryNNormalItems + (row - groupsItems);
}

- (NSString *)adReuseIdentifierForRow:(NSInteger)row {
    return [NSString stringWithFormat:@"AdCell_%ld", (long)row];
}

- (void)registerAdCellReuseIdentifiers {
    for (NSInteger row = 0; row < [self totalItemCount]; row++) {
        if ([self cellTypeForRow:row] != kCellTypeAd) {
            continue;
        }
        [self.tableView registerClass:[NativeListAdCell class]
               forCellReuseIdentifier:[self adReuseIdentifierForRow:row]];
    }
}

- (NativeListAdSlot *)adSlotForRow:(NSInteger)row {
    NSNumber *key = @(row);
    NativeListAdSlot *slot = self.adSlots[key];
    if (!slot) {
        slot = [[NativeListAdSlot alloc] init];
        slot.row = row;
        self.adSlots[key] = slot;
    }
    return slot;
}

- (nullable NativeListAdSlot *)adSlotForNativeAd:(MATNativeAd *)nativeAd {
    for (NativeListAdSlot *slot in self.adSlots.allValues) {
        if (slot.nativeAd == nativeAd) {
            return slot;
        }
    }
    return nil;
}

- (void)destroyAllAdSlots {
    for (NativeListAdSlot *slot in self.adSlots.allValues) {
        [slot destroyAd];
    }
    [self.adSlots removeAllObjects];
}

- (CGFloat)adShellWidthForTableView:(UITableView *)tableView {
    CGFloat width = CGRectGetWidth(tableView.bounds) - 16.0;
    if (width < 50.0) {
        width = [MATDemoTheme nativeCardWidth];
    }
    return MIN(MAX(width, 280.0), [MATDemoTheme nativeCardWidth]);
}

- (void)renderNativeAdOnceInSlot:(NativeListAdSlot *)slot tableView:(UITableView *)tableView {
    if (slot.hasRendered || !slot.nativeAd || !slot.nativeAd.nativeElements) {
        return;
    }

    CGFloat shellWidth = [self adShellWidthForTableView:tableView];
    for (UIView *sub in slot.adShellHost.subviews) {
        [sub removeFromSuperview];
    }
    [MATNativeAdRenderer renderNativeAd:slot.nativeAd inContainer:slot.adShellHost width:shellWidth];

    CGFloat shellHeight = [MATNativeAdRenderer preferredHeightForNativeAd:slot.nativeAd width:shellWidth];
    slot.cardHeight = shellHeight;
    slot.hasRendered = YES;
}

#pragma mark - MATNativeAdDelegate

- (void)nativeAdLoadSuccess:(MATNativeAd *)nativeAd {
    NativeListAdSlot *slot = [self adSlotForNativeAd:nativeAd];
    if (!slot) {
        return;
    }
    MATDemoAdLog(@"NativeList", @"didLoad", @"placement=%@ row=%ld", nativeAd.placementID ?: @"?", (long)slot.row);
    [self renderNativeAdOnceInSlot:slot tableView:self.tableView];

    NSIndexPath *path = [NSIndexPath indexPathForRow:slot.row inSection:0];
    if ([self.tableView.indexPathsForVisibleRows containsObject:path]) {
        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)nativeAdFailed:(MATNativeAd *)nativeAd withError:(NSError *)error {
    NativeListAdSlot *slot = [self adSlotForNativeAd:nativeAd];
    if (!slot) {
        return;
    }
    slot.loadFailed = YES;
    slot.errorMessage = @"Native ad load failed";
    if (slot.nativeAd) {
        [slot.nativeAd destroy];
        slot.nativeAd = nil;
    }
    MATDemoAdLog(@"NativeList", @"didFailWithError", @"placement=%@ row=%ld error=%@", nativeAd.placementID ?: @"?", (long)slot.row, MATDemoDescribeError(error));

    NSIndexPath *path = [NSIndexPath indexPathForRow:slot.row inSection:0];
    NativeListAdCell *cell = (NativeListAdCell *)[self.tableView cellForRowAtIndexPath:path];
    if ([cell isKindOfClass:[NativeListAdCell class]]) {
        [cell bindAdShellHost:slot.adShellHost
                     nativeAd:nil
                   loadFailed:YES
                 errorMessage:slot.errorMessage
                  hasRendered:NO];
    }
}

- (void)nativeAdDisplayed:(MATNativeAd *)nativeAd {
    NativeListAdSlot *slot = [self adSlotForNativeAd:nativeAd];
    MATDemoAdLog(@"NativeList", @"didDisplay", @"placement=%@ row=%ld", nativeAd.placementID ?: @"?", (long)slot.row);
}

- (void)nativeAd:(MATNativeAd *)nativeAd displayFailWithError:(NSError *)error {
    NativeListAdSlot *slot = [self adSlotForNativeAd:nativeAd];
    MATDemoAdLog(@"NativeList", @"displayFailWithError", @"placement=%@ row=%ld error=%@", nativeAd.placementID ?: @"?", (long)slot.row, MATDemoDescribeError(error));
}

- (void)nativeAdClicked:(MATNativeAd *)nativeAd {
    NativeListAdSlot *slot = [self adSlotForNativeAd:nativeAd];
    MATDemoAdLog(@"NativeList", @"didClick", @"placement=%@ row=%ld", nativeAd.placementID ?: @"?", (long)slot.row);
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self totalItemCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self cellTypeForIndexPath:indexPath] == kCellTypeAd) {
        NSString *reuseId = [self adReuseIdentifierForRow:indexPath.row];
        NativeListAdCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId forIndexPath:indexPath];
        NativeListAdSlot *slot = [self adSlotForRow:indexPath.row];
        [cell bindAdShellHost:slot.adShellHost
                     nativeAd:slot.nativeAd
                   loadFailed:slot.loadFailed
                 errorMessage:slot.errorMessage
                  hasRendered:slot.hasRendered];
        return cell;
    }
    NativeListNormalCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NormalCell" forIndexPath:indexPath];
    NSInteger normalIndex = [self normalIndexForRow:indexPath.row];
    cell.indexLabel.text = [NSString stringWithFormat:@"%ld", (long)(normalIndex + 1)];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self cellTypeForIndexPath:indexPath] == kCellTypeNormal) {
        return kNormalRowHeight;
    }
    NativeListAdSlot *slot = [self adSlotForRow:indexPath.row];
    if (slot.hasRendered) {
        return slot.cardHeight + 16.0 + 12.0;
    }
    return kAdLoadingRowHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self cellTypeForIndexPath:indexPath] != kCellTypeAd) {
        return;
    }
    NativeListAdSlot *slot = [self adSlotForRow:indexPath.row];
    if (slot.adLoadRequested || slot.hasRendered || slot.loadFailed) {
        return;
    }

    slot.adLoadRequested = YES;
    MATNativeAd *ad = [[MATNativeAd alloc] initWithPlacementID:MAT_DEMO_NATIVE_PLACEMENT_ID];
    ad.delegate = self;
    slot.nativeAd = ad;
    [MATNativeAdRenderer configureNativeAd:ad];
    [ad loadAd];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.isLoadingMore) {
        return;
    }
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat frameHeight = scrollView.frame.size.height;
    if (contentHeight <= frameHeight) {
        return;
    }
    if (offsetY > contentHeight - frameHeight - 120) {
        [self loadMoreIfNeeded];
    }
}

#pragma mark - Refresh / Load more

- (void)refreshList {
    self.isLoadingMore = NO;
    self.normalItemCount = kInitialNormalItemCount;
    [self destroyAllAdSlots];
    [self registerAdCellReuseIdentifiers];
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointZero animated:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
}

- (void)loadMoreIfNeeded {
    if (self.normalItemCount >= kMaxNormalItemCount) {
        return;
    }
    self.isLoadingMore = YES;

    NSInteger oldTotal = [self totalItemCount];
    NSInteger newNormalCount = MIN(kMaxNormalItemCount, self.normalItemCount + kPageNormalItemCount);
    if (newNormalCount == self.normalItemCount) {
        self.isLoadingMore = NO;
        return;
    }

    self.normalItemCount = newNormalCount;
    NSInteger newTotal = [self totalItemCount];
    for (NSInteger row = oldTotal; row < newTotal; row++) {
        if ([self cellTypeForRow:row] == kCellTypeAd) {
            [self.tableView registerClass:[NativeListAdCell class]
                   forCellReuseIdentifier:[self adReuseIdentifierForRow:row]];
        }
    }
    if (newTotal > oldTotal) {
        NSMutableArray<NSIndexPath *> *paths = [NSMutableArray array];
        for (NSInteger row = oldTotal; row < newTotal; row++) {
            [paths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
        }
        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView reloadData];
    }
    self.isLoadingMore = NO;
}

@end
