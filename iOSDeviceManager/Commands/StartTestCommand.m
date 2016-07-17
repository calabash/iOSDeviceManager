
#import "StartTestCommand.h"

static NSString *const DEVICE_ID_FLAG = @"-d";
static NSString *const TEST_BUNDLE_PATH_FLAG = @"-t";
static NSString *const TEST_RUNNER_PATH_FLAG = @"-r";
static NSString *const CODESIGN_IDENTITY_FLAG = @"-c";
static NSString *const UPDATE_TEST_RUNNER_FLAG = @"-u";
static NSString *const KEEP_ALIVE_FLAG = @"-k";

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
        
        [options addObject:[CommandOption withShortFlag:TEST_RUNNER_PATH_FLAG
                                               longFlag:@"--test-runner"
                                             optionName:@"path/to/testrunner.app"
                                                   info:@"Path to the test runner application which will run the test bundle"
                                               required:YES]];
        
        [options addObject:[CommandOption withShortFlag:TEST_BUNDLE_PATH_FLAG
                                               longFlag:@"--test-bundle"
                                             optionName:@"path/to/testbundle.xctest"
                                                   info:@"Path to the .xctest bundle"
                                               required:YES]];
        
        [options addObject:[CommandOption withShortFlag:CODESIGN_IDENTITY_FLAG
                                               longFlag:@"--codesign-identity"
                                             optionName:@"codesign-identity"
                                                   info:@"Identity used to codesign application resources [device only]"
                                               required:NO]];
        
        [options addObject:[CommandOption withShortFlag:UPDATE_TEST_RUNNER_FLAG
                                               longFlag:@"--update-runner"
                                             optionName:@"true-or-false,default=true"
                                                   info:@"When true, will reinstall the test runner if the device\
                            contains an older version than the bundle specified"
                                               required:NO]];
        
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
    BOOL update = YES;
    if ([[args allKeys] containsObject:UPDATE_TEST_RUNNER_FLAG]) {
        update = [args[UPDATE_TEST_RUNNER_FLAG] boolValue];
    }
    return [Device startTestOnDevice:args[DEVICE_ID_FLAG]
                      testRunnerPath:args[TEST_RUNNER_PATH_FLAG]
                      testBundlePath:args[TEST_BUNDLE_PATH_FLAG]
                    codesignIdentity:args[CODESIGN_IDENTITY_FLAG]
                    updateTestRunner:update
                           keepAlive:keepAlive];
}

@end
