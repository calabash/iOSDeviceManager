
#import "StartTestCommand.h"

static NSString *const DEVICE_ID_FLAG = @"-d";
static NSString *const TEST_BUNDLE_PATH_FLAG = @"-t";
static NSString *const TEST_RUNNER_PATH_FLAG = @"-r";
static NSString *const CODESIGN_IDENTITY_FLAG = @"-c";

@implementation StartTestCommand
+ (NSString *)name {
    return @"start_test";
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:CODESIGN_IDENTITY_FLAG
                                               longFlag:@"--codesign-identity"
                                             optionName:@"codesign-identity"
                                                   info:@"Identity used to codesign application resources [device only]"
                                               required:NO]];
        
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
        
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:@"device-identifier"
                                                   info:@"iOS Simulator GUID or 40-digit physical device ID"
                                               required:YES]];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [Device startTestOnDevice:args[DEVICE_ID_FLAG]
                      testRunnerPath:args[TEST_RUNNER_PATH_FLAG]
                      testBundlePath:args[TEST_BUNDLE_PATH_FLAG]
                    codesignIdentity:args[CODESIGN_IDENTITY_FLAG]];
}

@end
