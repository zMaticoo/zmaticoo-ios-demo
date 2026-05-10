//
//  SettingViewController.m
//  zmaticoo-ios-demo
//

#import "SettingViewController.h"
#import <MaticooSDK/MaticooSDK.h>

@interface SettingViewController ()
@property (nonatomic, strong) UISwitch *switchGdpr;
@property (nonatomic, strong) UISwitch *switchDoNotStatus;
@property (nonatomic, strong) UISwitch *switchCoppa;
@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Setting";
    self.view.backgroundColor = [self groupedBackgroundColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneTapped)];

    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-16],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-32],
    ]];

    self.switchGdpr = [[UISwitch alloc] init];
    self.switchDoNotStatus = [[UISwitch alloc] init];
    self.switchCoppa = [[UISwitch alloc] init];

    MaticooAds *sdk = [MaticooAds shareSDK];
    self.switchGdpr.on = [sdk getConsentStatus];
    self.switchDoNotStatus.on = [sdk getDoNotSell];
    self.switchCoppa.on = [sdk getIsAgeRestrictedUser];

    [self.switchGdpr addTarget:self action:@selector(gdprChanged:) forControlEvents:UIControlEventValueChanged];
    [self.switchDoNotStatus addTarget:self action:@selector(doNotStatusChanged:) forControlEvents:UIControlEventValueChanged];
    [self.switchCoppa addTarget:self action:@selector(coppaChanged:) forControlEvents:UIControlEventValueChanged];

    [stack addArrangedSubview:[self rowWithTitle:@"GDPR" switchView:self.switchGdpr]];
    [stack addArrangedSubview:[self rowWithTitle:@"DoNotStatus" switchView:self.switchDoNotStatus]];
    [stack addArrangedSubview:[self rowWithTitle:@"CoppaStatus" switchView:self.switchCoppa]];
}

- (UIColor *)groupedBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor systemGroupedBackgroundColor];
    }
    return [UIColor groupTableViewBackgroundColor];
}

- (UIView *)rowWithTitle:(NSString *)title switchView:(UISwitch *)sw {
    UIView *row = [[UIView alloc] init];
    row.backgroundColor = [self cardColor];
    row.layer.cornerRadius = 8;
    row.layer.masksToBounds = YES;

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont systemFontOfSize:16];
    label.translatesAutoresizingMaskIntoConstraints = NO;

    sw.translatesAutoresizingMaskIntoConstraints = NO;

    [row addSubview:label];
    [row addSubview:sw];

    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:12],
        [label.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:sw.leadingAnchor constant:-8],
        [sw.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-12],
        [sw.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [row.heightAnchor constraintGreaterThanOrEqualToConstant:44],
    ]];

    return row;
}

- (UIColor *)cardColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor secondarySystemGroupedBackgroundColor];
    }
    return [UIColor whiteColor];
}

- (void)doneTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)gdprChanged:(UISwitch *)sender {
    [[MaticooAds shareSDK] setConsentStatus:sender.isOn];
}

- (void)doNotStatusChanged:(UISwitch *)sender {
    [[MaticooAds shareSDK] setDoNotSell:sender.isOn];
}

- (void)coppaChanged:(UISwitch *)sender {
    [[MaticooAds shareSDK] setIsAgeRestrictedUser:sender.isOn];
}

@end
