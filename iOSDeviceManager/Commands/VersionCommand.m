#import "VersionCommand.h"
#import "ConsoleWriter.h"
#import "IDMVersionDefines.h"
#import "JSONUtils.h"

static NSString *const VERSION = @"2.0.0";
static NSString *const JSON_VERSION_FLAG = @"-j";
static NSString *const JSON_VERSION_OPTION_NAME = @"json";

@implementation VersionCommand
+ (NSString *)name {
    return @"version";
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:JSON_VERSION_FLAG
                                               longFlag:@"--json"
                                             optionName:JSON_VERSION_OPTION_NAME
                                                   info:@"Print version information as json"
                                               required:NO
                                             defaultVal:nil].asBooleanOption];
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
    if ([args objectForKey:JSON_VERSION_OPTION_NAME]) {
        ConsoleWrite(versionDetails.pretty);
    } else {
        [versionDetails enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            ConsoleWrite(@"%@=%@", key, value);
        }];
    }
    return iOSReturnStatusCodeEverythingOkay;
}
@end
