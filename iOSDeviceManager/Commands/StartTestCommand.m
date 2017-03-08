
#import "StartTestCommand.h"

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
    
    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }
    
    return [device startTestWithRunnerID:bundleID sessionID:sid keepAlive:keepAlive];
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:@"device-identifier"
                                                   info:@"iOS Simulator GUID or 40-digit physical device ID"
                                               required:NO
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:TEST_RUNNER_BUNDLE_ID_FLAG
                                               longFlag:@"--test-runner-bundle-id"
                                             optionName:@"test_runner_bundle_id"
                                                   info:@"BundleID of the Test Runner application (DeviceAgent)"
                                               required:NO
                                             defaultVal:@"com.apple.test.DeviceAgent-Runner"]];
        [options addObject:[CommandOption withShortFlag:SESSION_ID_FLAG
                                               longFlag:@"--session-id"
                                             optionName:@"session_id"
                                                   info:@"Session ID for the XCUITest"
                                               required:NO
                                             defaultVal:@"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"]];
        [options addObject:[CommandOption withShortFlag:KEEP_ALIVE_FLAG
                                               longFlag:@"--keep-alive"
                                             optionName:@"true-or-false"
                                                   info:@"Only set to false for smoke testing/debugging this tool"
                                               required:NO
                                             defaultVal:@(NO)]];
    });
    return options;
}

@end
