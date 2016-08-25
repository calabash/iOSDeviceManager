
#import "StartTestCommand.h"

static NSString *const DEVICE_ID_FLAG = @"-d";
static NSString *const TEST_RUNNER_BUNDLE_ID_FLAG = @"-b";
static NSString *const SESSION_ID_FLAG = @"-s";
static NSString *const KEEP_ALIVE_FLAG = @"-k";

@implementation StartTestCommand
+ (NSString *)name {
    return @"start_test";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    BOOL keepAlive = YES;
    if ([args.allKeys containsObject:KEEP_ALIVE_FLAG]) {
        keepAlive = [args[KEEP_ALIVE_FLAG] boolValue];
    }
    
    NSString *bundleID = [self optionDict][TEST_RUNNER_BUNDLE_ID_FLAG].defaultValue;
    if ([args.allKeys containsObject:TEST_RUNNER_BUNDLE_ID_FLAG]) {
        bundleID = args[TEST_RUNNER_BUNDLE_ID_FLAG];
    }
    
    NSString *sessionID = [self optionDict][SESSION_ID_FLAG].defaultValue;
    if ([args.allKeys containsObject:SESSION_ID_FLAG]) {
        sessionID = args[SESSION_ID_FLAG];
    }
    
    NSUUID *sid = [[NSUUID alloc] initWithUUIDString:sessionID];
    NSAssert(sid, @"%@ is not a valid UUID", sid);
    
    return [Device startTestOnDevice:args[DEVICE_ID_FLAG]
                           sessionID:sid
                      runnerBundleID:bundleID
                           keepAlive:keepAlive];
}

@end
