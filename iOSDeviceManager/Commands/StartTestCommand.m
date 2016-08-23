
#import "StartTestCommand.h"

static NSString *const DEVICE_ID_FLAG = @"-d";
static NSString *const TEST_RUNNER_BUNDLE_ID_FLAG = @"-b";
static NSString *const SESSION_ID_FLAG = @"-s";
static NSString *const KEEP_ALIVE_FLAG = @"-k";

static NSString *const DEFAULT_BUNDLE_ID = @"com.apple.test.DeviceAgent-Runner";
static NSString *const DEFAULT_SESSION_ID = @"CBX-BEEFBABE-FEED-BABE-BEEF-CAFEBEEFFACE";

@implementation StartTestCommand
+ (NSString *)name {
    return @"start_test";
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
                                               required:YES]];
        
        [options addObject:[CommandOption withShortFlag:TEST_RUNNER_BUNDLE_ID_FLAG
                                               longFlag:@"--test-runner-bundle-id"
                                             optionName:@"test_runner_bundle_id,default=com.apple.test.DeviceAgent-Runner"
                                                   info:@"BundleID of the Test Runner application (DeviceAgent)"
                                               required:YES]];
        
        [options addObject:[CommandOption withShortFlag:SESSION_ID_FLAG
                                               longFlag:@"--session-id"
                                             optionName:@"session_id,default=CBX-BEEFBABE-FEED-BABE-BEEF-CAFEBEEFFACE"
                                                   info:@"BundleID of the Test Runner application (DeviceAgent)"
                                               required:YES]];
        
        [options addObject:[CommandOption withShortFlag:KEEP_ALIVE_FLAG
                                               longFlag:@"--keep-alive"
                                             optionName:@"true-or-false"
                                                   info:@"Only set to false for smoke testing/debugging this tool"
                                               required:NO]];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    BOOL keepAlive = YES;
    if ([args.allKeys containsObject:KEEP_ALIVE_FLAG]) {
        keepAlive = [args[KEEP_ALIVE_FLAG] boolValue];
    }
    
    NSString *bundleID = DEFAULT_BUNDLE_ID;
    if ([args.allKeys containsObject:TEST_RUNNER_BUNDLE_ID_FLAG]) {
        bundleID = args[TEST_RUNNER_BUNDLE_ID_FLAG];
    }
    
    NSString *sessionID = DEFAULT_SESSION_ID;
    if ([args.allKeys containsObject:SESSION_ID_FLAG]) {
        sessionID = args[SESSION_ID_FLAG];
    }
    
    NSUUID *sid = [[NSUUID alloc] initWithUUIDString:sessionID];
    
    return [Device startTestOnDevice:args[DEVICE_ID_FLAG]
                           sessionID:sid
                      runnerBundleID:bundleID
                           keepAlive:keepAlive];
}

@end
