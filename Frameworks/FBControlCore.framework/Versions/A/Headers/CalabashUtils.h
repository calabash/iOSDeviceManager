#import <Foundation/Foundation.h>

@interface CalabashUtils : NSObject

+ (void)doOnMain:(void(^)(void))someWork;
+ (id)doOnMainAndReturn:(id(^)(void))someResult;

+ (NSString *)logfileLocation:(NSError **)err;

@end
