//
//  AppDelegate.h
//  zmaticoo-ios-demo
//
//  Created by york.dong on 2026/5/9.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

/// Used when running below iOS 13 (no UIScene); required for iOS 12 window bootstrap.
@property (nonatomic, strong) UIWindow *window;

@end

