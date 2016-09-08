#import <Foundation/Foundation.h>

@interface ThreadUtils : NSObject
+ (void)concurrentlyEnumerate:(NSArray *)array withBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;
+ (void)runUntilAllComplete:(NSArray <NSOperation *> *)ops;
@end
