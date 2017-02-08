#import <Foundation/Foundation.h>

@interface CodesignResources : NSObject

+ (NSString *)CalabashPermissionsProfilePath;
+ (NSString *)CalabashWildcardProfilePath;
+ (NSString *)TaskyIpaPath;
+ (NSString *)TaskyAppBundleID;
+ (NSString *)PermissionsAppBundleID;
+ (NSString *)PermissionsIpaPath;
+ (NSString *)CalabashDylibPath;

@end
