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

+ (void)initialize {
    const char *FBLog = [ShellRunner verbose] ? "YES" : "NO";
    setenv("FBCONTROLCORE_LOGGING", FBLog, 1);
    setenv("FBCONTROLCORE_DEBUG_LOGGING", FBLog, 1);
}

+ (iOSReturnStatusCode)startTestOnDevice:(NSString *)deviceID
                               sessionID:(NSUUID *)sessionID
                          runnerBundleID:(NSString *)runnerBundleID
                               keepAlive:(BOOL)keepAlive {

    if ([TestParameters isDeviceID:deviceID]) {
        return [PhysicalDevice startTestOnDevice:deviceID
                                       sessionID:sessionID
                                  runnerBundleID:runnerBundleID
                                       keepAlive:keepAlive];
    } else {
        return [Simulator startTestOnDevice:deviceID
                                  sessionID:sessionID
                             runnerBundleID:runnerBundleID
                                  keepAlive:keepAlive];
    }
}

+ (iOSReturnStatusCode)installApp:(NSString *)pathToBundle
                         deviceID:(NSString *)deviceID
                        updateApp:(BOOL)updateApp
                       codesignID:(NSString *)codesignID {
    if ([TestParameters isDeviceID:deviceID]) {
        return [PhysicalDevice installApp:pathToBundle
                                 deviceID:deviceID
                                updateApp:updateApp
                               codesignID:codesignID];
    } else {
        return [Simulator installApp:pathToBundle
                            deviceID:deviceID
                           updateApp:updateApp
                          codesignID:nil];
    }
}

+ (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID
                           deviceID:(NSString *)deviceID {
    if ([TestParameters isSimulatorID:deviceID]) {
        return [Simulator uninstallApp:bundleID deviceID:deviceID];
    } else {
        return [PhysicalDevice uninstallApp:bundleID deviceID:deviceID];
    }
}

+ (iOSReturnStatusCode)appIsInstalled:(NSString *)bundleID
                             deviceID:(NSString *)deviceID {
    if ([TestParameters isSimulatorID:deviceID]) {
        return [Simulator appIsInstalled:bundleID deviceID:deviceID];
    } else {
        return [PhysicalDevice appIsInstalled:bundleID deviceID:deviceID];
    }
}

+ (iOSReturnStatusCode)setLocation:(NSString *)deviceID
                               lat:(double)lat
                               lng:(double)lng {
    if ([TestParameters isSimulatorID:deviceID]) {
        return [Simulator setLocation:deviceID
                                  lat:lat
                                  lng:lng];
    } else {
        return [PhysicalDevice setLocation:deviceID
                                       lat:lat
                                       lng:lng];
    }
}

+ (NSDictionary *)infoPlistForInstalledBundleID:(NSString *)bundleID
                                       deviceID:(NSString *)deviceID {
    if ([TestParameters isSimulatorID:deviceID]) {
        return [Simulator infoPlistForInstalledBundleID:bundleID
                                               deviceID:deviceID];
    } else {
        return [PhysicalDevice infoPlistForInstalledBundleID:bundleID
                                                    deviceID:deviceID];
    }
}

+ (iOSReturnStatusCode)uploadFile:(NSString *)filepath
                         toDevice:(NSString *)deviceID
                   forApplication:(NSString *)bundleID
                        overwrite:(BOOL)overwrite {
    if ([TestParameters isSimulatorID:deviceID]) {
        return [Simulator uploadFile:filepath
                            toDevice:deviceID
                      forApplication:bundleID
                           overwrite:overwrite];
    } else {
        return [PhysicalDevice
                uploadFile:filepath
                toDevice:deviceID
                forApplication:bundleID
                overwrite:overwrite];
    }
}

@end
