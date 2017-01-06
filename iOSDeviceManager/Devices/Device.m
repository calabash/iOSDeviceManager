#import "PhysicalDevice.h"
#import "ShellRunner.h"
#import "Simulator.h"
#import "AppUtils.h"
#import "ConsoleWriter.h"

#define MUST_OVERRIDE @throw [NSException exceptionWithName:@"ProgrammerErrorException" reason:@"Method should be overridden by a subclass" userInfo:@{@"method" : NSStringFromSelector(_cmd)}]

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

@implementation Device

- (id)init {
    if (self = [super init]) {
        _testingComplete = NO;
    }
    return self;
}

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

+ (Device *)withID:(NSString *)uuid {
    if ([self isSimulatorID:uuid]) { return [Simulator withID:uuid]; }
    if ([self isDeviceID:uuid]) { return [PhysicalDevice withID:uuid]; }
    @throw [NSException exceptionWithName:@"InvalidDeviceID"
                                   reason:@"Specified ID does not match simulator or device"
                                 userInfo:nil];
}

+ (NSArray<FBDevice *> *)availableDevices {
    return [[FBDeviceSet defaultSetWithLogger:nil error:nil] allDevices];
}

+ (NSArray<FBSimulator *> *)availableSimulators {
    FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration
                                                      configurationWithDeviceSetPath:nil
                                                      options:FBSimulatorManagementOptionsIgnoreSpuriousKillFail];
    
    NSError *err;
    FBSimulatorControl *simControl = [FBSimulatorControl withConfiguration:configuration error:&err];
    if (err) {
        ConsoleWriteErr(@"Error creating FBSimulatorControl: %@", err);
        @throw [NSException exceptionWithName:@"GenericException"
                                       reason:@"Failed detecting available simulators"
                                     userInfo:nil];
    }
    
    return [[simControl set] allSimulators];
}

+ (FBSimulator *)defaultSimulator:(NSArray<FBSimulator *>*)simulators {
    NSArray <FBSimulator *> *sorted = [simulators sortedArrayUsingComparator:^NSComparisonResult(id sim2, id sim1) {
        return [Device comparePreferredSimulator:sim1 to:sim2];
    }];
    return [sorted firstObject];
}

+ (NSComparisonResult)comparePreferredSimulator:(FBSimulator *)sim to:(FBSimulator *)otherSim {
    NSDecimalNumber *simVersion = [sim.osConfiguration versionNumber];
    NSDecimalNumber *otherSimVersion = [otherSim.osConfiguration versionNumber];
    NSString *simDeviceName = [sim.deviceConfiguration deviceName];
    NSString *otherSimDeviceName = [otherSim.deviceConfiguration deviceName];
    
    if ([simVersion isGreaterThan:otherSimVersion]) {
        // NSOrderedAscending - The left operand is smaller than the right operand.
        return NSOrderedDescending;
    } else if ([simVersion isEqual:otherSimVersion]) {
        if ([simDeviceName containsString:@"iPhone"] && [otherSimDeviceName containsString:@"iPhone"]) {
            NSCharacterSet *nonDigitCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
            NSString *simNumber = [[simDeviceName componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
            NSString *otherSimNumber = [[otherSimDeviceName componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
            if (simNumber.length == 0) {
                return NSOrderedAscending;
            }
            if (otherSimNumber.length == 0) {
                return NSOrderedDescending;
            }
            if (fabs(simNumber.doubleValue - otherSimNumber.doubleValue) < 0.001) {
                // Handle things like 6S vs 6
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".+\\d+[Ss]" options:0 error:nil];
                BOOL simIsS = [regex numberOfMatchesInString:simDeviceName options:0 range:NSMakeRange(0, [simDeviceName length])];
                BOOL otherSimIsS = [regex numberOfMatchesInString:otherSimDeviceName options:0 range:NSMakeRange(0, [otherSimDeviceName length])];

                if (simIsS && !otherSimIsS) {
                    return NSOrderedDescending;
                }
            } else if ((simNumber.doubleValue - otherSimNumber.doubleValue) > 0.001) {
                return NSOrderedDescending;
            } else {
                return NSOrderedAscending;
            }
        } else if ([simDeviceName containsString:@"iPhone"] && ![otherSimDeviceName containsString:@"iPhone"]) {
            return NSOrderedDescending;
        }
    }
    
    return NSOrderedAscending;;
}

+ (NSString *)defaultDeviceID {
    
    NSArray<FBDevice *> *devices = [Device availableDevices];
    
    if ([devices count] == 1) {
        return [devices firstObject].udid;
    } else if ([devices count] > 1) {
        @throw [NSException exceptionWithName:@"AmbiguousArgumentsException"
                                       reason:@"Multiple physical devices detected but none specified"
                                     userInfo:nil];
    } else {
        NSArray<FBSimulator *> *sims = [Device availableSimulators];
        return [Device defaultSimulator:sims].udid;
    }
}

+ (void)initialize {
    const char *FBLog = [ShellRunner verbose] ? "YES" : "NO";
    setenv("FBCONTROLCORE_LOGGING", FBLog, 1);
    setenv("FBCONTROLCORE_DEBUG_LOGGING", FBLog, 1);
}

- (iOSReturnStatusCode)launch {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)kill {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)installApp:(Application *)app shouldUpdate:(BOOL)shouldUpdate {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)simulateLocationWithLat:(double)lat lng:(double)lng {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)stopSimulatingLocation {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)launchApp:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)killApp:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)isInstalled:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (Application *)installedApp:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)startTestWithRunnerID:(NSString *)runnerID sessionID:(NSUUID *)sessionID keepAlive:(BOOL)keepAlive {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)uploadFile:(NSString *)filepath forApplication:(NSString *)bundleID overwrite:(BOOL)overwrite {
    MUST_OVERRIDE;
}

@end
