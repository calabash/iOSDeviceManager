#import "PhysicalDevice.h"
#import "ShellRunner.h"
#import "Simulator.h"
#import "AppUtils.h"

@implementation Device

- (id)init {
    if (self = [super init]) {
        _testingComplete = NO;
    }
    return self;
}

+ (Device *)withID:(NSString *)uuid {
    if ([self isSimID:uuid]) { return [Simulator withID:uuid]; }
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
    
    FBSimulatorControl *simControl = [FBSimulatorControl withConfiguration:configuration error:nil];
    
    return [[simControl set] allSimulators];
}

+ (FBSimulator *)defaultSimulator:(NSArray<FBSimulator *>*)simulators {
    NSArray <FBSimulator *> *sorted = [simulators sortedArrayUsingComparator:^NSComparisonResult(id sim1, id sim2) {
        return ![Device isPreferredSimulator:sim1 comparedTo:sim2];
    }];
    return [sorted firstObject];
}

+ (BOOL)isPreferredSimulator:(FBSimulator *)sim comparedTo:(FBSimulator *)otherSim {
    NSDecimalNumber *simVersion = [sim.osConfiguration versionNumber];
    NSDecimalNumber *otherSimVersion = [otherSim.osConfiguration versionNumber];
    NSString *simDeviceName = [sim.deviceConfiguration deviceName];
    NSString *otherSimDeviceName = [otherSim.deviceConfiguration deviceName];
    
    if ([simVersion isGreaterThan:otherSimVersion]) {
        return YES;
    } else if ([simVersion isEqual:otherSimVersion]) {
        if ([simDeviceName containsString:@"iPhone"] && [otherSimDeviceName containsString:@"iPhone"]) {
            NSCharacterSet *nonDigitCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
            NSString *simNumber = [[simDeviceName componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
            NSString *otherSimNumber = [[otherSimDeviceName componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
            if (simNumber.length == 0) {
                return NO;
            }
            if (otherSimNumber.length == 0) {
                return YES;
            }
            if ([simNumber doubleValue] == [otherSimNumber doubleValue]) {
                // Handle things like 6S vs S
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".+\\d+s" options:0 error:nil];
                BOOL simIsS = [regex numberOfMatchesInString:simDeviceName options:0 range:NSMakeRange(0, [simDeviceName length])];
                BOOL otherSimIsS = [regex numberOfMatchesInString:otherSimDeviceName options:0 range:NSMakeRange(0, [otherSimDeviceName length])];

                if (simIsS && !otherSimIsS) {
                    return YES;
                }
            } else if ([simNumber doubleValue] > [otherSimNumber doubleValue]) {
                return YES;
            } else {
                return NO;
            }
        } else if ([simDeviceName containsString:@"iPhone"] && ![otherSimDeviceName containsString:@"iPhone"]) {
            return YES;
        }
    }
    
    return NO;
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

+ (BOOL)isSimID:(NSString *)uuid {
    
    if ([TestParameters isSimulatorID:uuid]) {
        return true;
    }
    
    return false;
}

+ (BOOL)isDeviceID:(NSString *)uuid {
    
    if ([TestParameters isDeviceID:uuid]) {
        return true;
    }
    
    return false;
}

+ (void)initialize {
    const char *FBLog = [ShellRunner verbose] ? "YES" : "NO";
    setenv("FBCONTROLCORE_LOGGING", FBLog, 1);
    setenv("FBCONTROLCORE_DEBUG_LOGGING", FBLog, 1);
}

- (iOSReturnStatusCode)launch {
    @throw [NSException exceptionWithName:@"ProgrammerException"
                                   reason:@"PhysicalDevice or Simulator subclass should be used"
                                 userInfo:nil];
}

- (iOSReturnStatusCode)kill {
    @throw [NSException exceptionWithName:@"ProgrammerException"
                                   reason:@"PhysicalDevice or Simulator subclass should be used"
                                 userInfo:nil];
}

- (iOSReturnStatusCode)installApp:(FBApplicationDescriptor *)app updateApp:(BOOL)updateApp {
    @throw [NSException exceptionWithName:@"ProgrammerException"
                                   reason:@"PhysicalDevice or Simulator subclass should be used"
                                 userInfo:nil];
}

- (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID {
    @throw [NSException exceptionWithName:@"ProgrammerException"
                                   reason:@"PhysicalDevice or Simulator subclass should be used"
                                 userInfo:nil];
}

- (iOSReturnStatusCode)simulateLocationWithLat:(double)lat lng:(double)lng {
    @throw [NSException exceptionWithName:@"ProgrammerException"
                                   reason:@"PhysicalDevice or Simulator subclass should be used"
                                 userInfo:nil];
}

- (iOSReturnStatusCode)stopSimulatingLocation {
    @throw [NSException exceptionWithName:@"ProgrammerException"
                                   reason:@"PhysicalDevice or Simulator subclass should be used"
                                 userInfo:nil];
}

- (iOSReturnStatusCode)launchApp:(NSString *)bundleID {
    @throw [NSException exceptionWithName:@"ProgrammerException"
                                   reason:@"PhysicalDevice or Simulator subclass should be used"
                                 userInfo:nil];
}

- (iOSReturnStatusCode)killApp:(NSString *)bundleID {
    @throw [NSException exceptionWithName:@"ProgrammerException"
                                   reason:@"PhysicalDevice or Simulator subclass should be used"
                                 userInfo:nil];
}

- (BOOL)isInstalled:(NSString *)bundleID {
    @throw [NSException exceptionWithName:@"ProgrammerException"
                                   reason:@"PhysicalDevice or Simulator subclass should be used"
                                 userInfo:nil];
}

- (FBApplicationDescriptor *)installedApp:(NSString *)bundleID {
    @throw [NSException exceptionWithName:@"ProgrammerException"
                                   reason:@"PhysicalDevice or Simulator subclass should be used"
                                 userInfo:nil];
}

- (iOSReturnStatusCode)startTestWithRunnerID:(NSString *)runnerID sessionID:(NSUUID *)sessionID keepAlive:(BOOL)keepAlive {
    @throw [NSException exceptionWithName:@"ProgrammerException"
                                   reason:@"PhysicalDevice or Simulator subclass should be used"
                                 userInfo:nil];
}

- (iOSReturnStatusCode)uploadFile:(NSString *)filepath forApplication:(NSString *)bundleID overwrite:(BOOL)overwrite {
    @throw [NSException exceptionWithName:@"ProgrammerException"
                                   reason:@"PhysicalDevice or Simulator subclass should be used"
                                 userInfo:nil];
}

@end
