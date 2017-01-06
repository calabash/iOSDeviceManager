
#import <Foundation/Foundation.h>

@interface AppUtils : NSObject
+ (BOOL)appVersionIsDifferent:(NSDictionary *)oldPlist newPlist:(NSDictionary *)newPlist;
+ (NSString *)copyAppBundleToTmpDir:(NSString *)bundlePath;
+ (NSString *)unzipIpa:(NSString*)ipaPath;
@end
