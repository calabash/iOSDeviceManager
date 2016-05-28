
#import "SimulatorTestParameters.h"
#import "DeviceTestParameters.h"

@interface NSString(Base64)
- (BOOL)isBase64;
@end

@implementation NSString(Base64)
- (BOOL)isBase64 {
    for (int i = 0; i < self.length; i++) {
        char c =  toupper([self characterAtIndex:i]);
        if (c < '0' || c > 'F') { return NO; }
    }
    return YES;
}
@end

@implementation TestParameters

//F8C4D65B-2FB7-4B8B-89BE-8C3982E65F3F
+ (BOOL)isSimulatorID:(NSString *)did {
    NSArray <NSString *>*parts = [did componentsSeparatedByString:@"-"];
    NSUUID *u = [[NSUUID alloc] initWithUUIDString:did];
    return did.length == 36
        && u != nil
        && parts.count == 5
        && parts[0].length == 8
        && parts[1].length == 4
        && parts[2].length == 4
        && parts[3].length == 4
        && parts[4].length == 12;
}

+ (BOOL)isDeviceID:(NSString *)did {
    return did.length == 40 && [did isBase64];
}

+ (instancetype)fromJSON:(NSDictionary *)json {
    NSAssert(json[DEVICE_ID_FLAG], @"Must specify a device id with %@", DEVICE_ID_FLAG);
    if ([self isSimulatorID:json[DEVICE_ID_FLAG]]) {
        return [[SimulatorTestParameters fromJSON:json] validate];
    } else {
        return [[DeviceTestParameters fromJSON:json] validate];
    }
}

- (DeviceTestParameters *)asDeviceTestParameters {
    NSAssert(self.deviceType == kDeviceTypeDevice, @"Can not make device params from simulator params");
    return (DeviceTestParameters *)self;
}

- (SimulatorTestParameters *)asSimulatorTestParameters {
    NSAssert(self.deviceType == kDeviceTypeSimulator, @"Can not make simulator params from device params");
    return (SimulatorTestParameters *)self;
}

- (instancetype)validate {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (self.testBundlePath == nil) {
        [self failWith:[NSString stringWithFormat:@"Must provide a test bundle path (.xctest). Use the %@ flag", XCTEST_BUNDLE_PATH_FLAG]];
    }
    
    if (self.testRunnerPath == nil) {
        [self failWith:[NSString stringWithFormat:@"Must provide a path to the TestRunner.app. Use the %@ flag",
                        TEST_RUNNER_PATH_FLAG]];
    }
    
    if (![fm fileExistsAtPath:self.testBundlePath]) {
        [self failWith:[NSString stringWithFormat:@"Test bundle doesn't exist at path: %@", self.testBundlePath]];
    }
    
    if (![fm fileExistsAtPath:self.testRunnerPath]) {
        [self failWith:[NSString stringWithFormat:@"Test Runner app doesn't exist at path: %@", self.testRunnerPath]];
    }
    
    return self;
}

- (void)failWith:(NSString *)message {
    [self failWith:message exitCode:1];
}

- (void)failWith:(NSString *)message exitCode:(int)exitCode {
    NSLog(@"%@", message);
    exit(exitCode);
}

@end
