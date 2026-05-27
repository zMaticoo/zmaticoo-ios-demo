//
//  MATDemoLog.m
//  zmaticoo-ios-demo
//

#import "MATDemoLog.h"
#import <stdarg.h>

void MATDemoAdLog(NSString *unit, NSString *event, NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *detail = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSLog(@"[zMaticooDemo][%@] %@ %@", unit, event, detail);
}

NSString *MATDemoDescribeError(NSError *error) {
    if (!error) {
        return @"—";
    }
    return [NSString stringWithFormat:@"%@ (%ld)", error.localizedDescription ?: @"", (long)error.code];
}
