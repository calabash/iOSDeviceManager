#import "VersionCommand.h"
#import "ConsoleWriter.h"
#import "IDMVersionDefines.h"

NSString *const VERSION = @"2.0.0";

@implementation VersionCommand
+ (NSString *)name {
    return @"version";
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    NSDictionary *versionDetails = @{
                                     @"VERSION" : VERSION,
                                     @"GIT_SHORT_REVISION": IDM_GIT_SHORT_REVISION,
                                     @"GIT_BRANCH": IDM_GIT_BRANCH,
                                     @"GIT_REMOTE_ORIGIN": IDM_GIT_REMOTE_ORIGIN
                                     };
    [versionDetails enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        ConsoleWrite(@"%@=%@\n", key, value);
    }];
    return iOSReturnStatusCodeEverythingOkay;
}
@end
