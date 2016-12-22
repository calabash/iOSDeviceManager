
#import <Foundation/Foundation.h>

@interface AppUtils : NSObject
+ (BOOL)appVersionIsDifferent:(NSDictionary *)oldPlist newPlist:(NSDictionary *)newPlist;
+ (NSString *)copyAppBundle:(NSString *)bundlePath;
+ (NSString *)unzipIpa:(NSString*)ipaPath;
@end
