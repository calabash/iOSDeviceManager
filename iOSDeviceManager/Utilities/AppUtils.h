
#import <Foundation/Foundation.h>

@interface AppUtils : NSObject
+ (BOOL)appVersionIsDifferent:(NSDictionary *)oldPlist newPlist:(NSDictionary *)newPlist;
@end
