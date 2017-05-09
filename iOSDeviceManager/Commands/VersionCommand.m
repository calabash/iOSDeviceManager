#import "VersionCommand.h"
#import "ConsoleWriter.h"

NSString *const VERSION = @"0.0.1";

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
    ConsoleWrite(@"%@", versionDetails);
    return iOSReturnStatusCodeEverythingOkay;
}
@end
