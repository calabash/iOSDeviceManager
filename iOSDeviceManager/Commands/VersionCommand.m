
#import "VersionCommand.h"
#import "ConsoleWriter.h"
#import "IDMVersionDefines.h"
#import "JSONUtils.h"

static NSString *const VERSION = @"3.8.1";
static NSString *const JSON_VERSION_FLAG = @"-j";
static NSString *const JSON_VERSION_OPTION_NAME = @"json";

#ifdef IDM_GIT_SHORT_REVISION
static NSString *const kGitShortRevision = IDM_GIT_SHORT_REVISION;
#else
static NSString *const kGitShortRevision = @"Unknown";
#endif

#ifdef IDM_GIT_BRANCH
static NSString *const kGitBranch = IDM_GIT_BRANCH;
#else
static NSString *const kGitBranch = @"Unknown";
#endif

#ifdef IDM_GIT_REMOTE_ORIGIN
static NSString *const kGitRemoteOrigin = IDM_GIT_REMOTE_ORIGIN;
#else
static NSString *const kGitRemoteOrigin = @"Unknown";
#endif

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
    if ([args objectForKey:JSON_VERSION_OPTION_NAME]) {
        NSDictionary *versionDetails = @{
                                         @"VERSION" : VERSION,
                                         @"GIT_SHORT_REVISION": kGitShortRevision,
                                         @"GIT_BRANCH": kGitBranch,
                                         @"GIT_REMOTE_ORIGIN": kGitRemoteOrigin,
                                         };

        NSString *json = [versionDetails pretty];
        json = [json stringByReplacingOccurrencesOfString:@"\\"
                                               withString:@""];
        ConsoleWrite(@"%@", json);
    } else {
        ConsoleWrite(@"%@", VERSION);
    }
    return iOSReturnStatusCodeEverythingOkay;
}

@end
