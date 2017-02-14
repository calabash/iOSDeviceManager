
#import <Foundation/Foundation.h>

@interface AppUtils : NSObject
+ (BOOL)appVersionIsDifferent:(NSDictionary *)oldPlist newPlist:(NSDictionary *)newPlist;
+ (NSString *)copyAppBundleToTmpDir:(NSString *)bundlePath;
+ (NSString *)unzipIpa:(NSString*)ipaPath;

/*
    Returns true if it follows the regex ^([a-zA-Z0-9_-]+\.)+[a-zA-Z0-9_-]+$
    Which, in english, is any number of repetitions of "<token>." followed by a final <token>
    where <token> is case insensitive alphanumeric characters, underscore, or -.
 
    TODO: Verify the valid bundle_id char set! 
 */
+ (BOOL)isBundleID:(NSString *)maybeBundleID;
@end
