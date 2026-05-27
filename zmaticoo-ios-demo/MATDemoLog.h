//
//  MATDemoLog.h
//  zmaticoo-ios-demo
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void MATDemoAdLog(NSString *unit, NSString *event, NSString *fmt, ...) NS_FORMAT_FUNCTION(3, 4);
NSString *MATDemoDescribeError(NSError * _Nullable error);

NS_ASSUME_NONNULL_END
