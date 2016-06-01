
#import "TestParameters.h"
#import "TestControlArgParser.h"

@implementation TestControlArgParser

static NSString *progname = @"test-control";

static NSDictionary *flagDescriptions;
static NSDictionary *flagRequirementDict;

+ (void)printUsage {
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
    printf("%s", [usageString UTF8String]);
}

+ (NSDictionary *)parseArgs:(NSArray<NSString *> *)arguments {
    flagDescriptions = @{
                         XCTEST_BUNDLE_PATH_FLAG: @"Path to .xctest bundle (probably inside the test runner's PlugIns directory)",
                         CODESIGN_IDENTITY_FLAG: @"[Device Only] Codesign Identity (e.g. 'iPhone Developer: Aaron Aaronson (ABCDE12345)')",
                         DEVICE_ID_FLAG: @"Device ID e.g. 'F8C4D65B-2FB7-4B8B-89BE-8C3982E65F3F' (for Simulators), \
                             \n\t\tor 40 char Device ID for physical devices, e.g. 49a29c9e61998623e7909e35e8bae50dd07ef85f",
                         TEST_RUNNER_PATH_FLAG: @"Path to Test Runner .app directory"
                         };

    if (arguments.count == 1) {
        printf("test-control\n\n");
        NSString *licenseInfo;
        licenseInfo = @"Released under BSD 3-Clause License\n\
https://github.com/calabash/test-control/blob/master/LICENSE\n\
https://github.com/calabash/test-control/blob/master/vendor-licenses\n";
        printf("%s", [licenseInfo UTF8String]);

        [self printUsage];

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
        if (![flags containsObject:arguments[i]]) {
            NSLog(@"'%@' isn't a supported flag.", arguments[i]);
            [self printUsage];
            exit(3);
        }
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
@end
