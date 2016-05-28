
#import "DeviceTestParameters.h"
#import <Foundation/Foundation.h>
#import "Simulator.h"
#import "Device.h"

static NSString *progname = @"test-control";

static NSDictionary *flagDescriptions;
static NSDictionary *flagRequirementDict;

void printUsage() {
    
    NSArray *flags = @[
                       TEST_RUNNER_PATH_FLAG,
                       XCTEST_BUNDLE_PATH_FLAG,
                       CODESIGN_IDENTITY_FLAG,
                       DEVICE_ID_FLAG
                       ];
    
    NSMutableString *usageString = [NSMutableString string];
    
    [usageString appendFormat:@"\nUsage: %@", progname];
    
    for (NSString *flag in flags) {
        [usageString appendFormat:@"\n\t%@\t%@", flag, flagDescriptions[flag]];
    }
    NSLog(@"%@", usageString);
}

NSDictionary *parseArgs() {
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    if (arguments.count == 1) {
        printUsage();
        exit(1);
    }
    NSArray *flags = @[
                       TEST_RUNNER_PATH_FLAG,
                       XCTEST_BUNDLE_PATH_FLAG,
                       CODESIGN_IDENTITY_FLAG,
                       DEVICE_ID_FLAG
                       ];
    NSMutableDictionary *args = [NSMutableDictionary dictionary];
    for (int i = 1; i < arguments.count; i++) {
        if (arguments.count == i + 1 || [flags containsObject:arguments[i+1]]) {
            NSString *flag = arguments[i];
            NSLog(@"No value specified for flag: %@ [%@]", flag, flagDescriptions[flag]);
            exit(2);
        }
        NSString *flag = arguments[i++];
        NSString *val = arguments[i];
        args[flag] = val;
    }

    return args;
}

void init() {
    flagDescriptions = @{
                         XCTEST_BUNDLE_PATH_FLAG: @"Path to .xctest bundle (probably inside the test runner's PlugIns directory)",
                         CODESIGN_IDENTITY_FLAG: @"Codesign Identity (e.g. 'iPhone Developer: Aaron Aaronson (ABCDE12345)'",
                         DEVICE_ID_FLAG: @"Device name (for Simulators) e.g. 'iPhone 5s (9.0)', \
                             or 40 char Device ID for physical devices, e.g. 49a29c9e61998623e7909e35e8bae50dd07ef85f",
                         TEST_RUNNER_PATH_FLAG: @"Path to Test Runner .app directory"
                         };
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        init();
        
        TestParameters *params = [TestParameters fromJSON:parseArgs()];
        
        if (params.deviceType == kDeviceTypeDevice) {
            [Device startTest:params.asDeviceTestParameters];
        } else {
            [Simulator startTest:params.asSimulatorTestParameters];
        }

        if (![Simulator startTest:params.asSimulatorTestParameters]) {
            exit(2);
        }
    }
    return 0;
}
