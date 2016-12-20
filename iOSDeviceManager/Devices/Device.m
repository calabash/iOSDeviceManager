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

+ (NSString *)defaultDeviceID {
    NSArray<FBDevice *> *devices = [[FBDeviceSet defaultSetWithLogger:nil error:nil] allDevices];
    
    FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration
                                                      configurationWithDeviceSetPath:nil
                                                      options:FBSimulatorManagementOptionsIgnoreSpuriousKillFail];
    
    FBSimulatorControl *simControl = [FBSimulatorControl withConfiguration:configuration error:nil];
        
    NSArray<FBSimulator *> *sims = [[simControl set] allSimulators];
    
    if ([devices count] > 0) {
        return [devices firstObject].udid;
    } else {
        FBSimulator *candidate;
        for (FBSimulator *sim in sims) {
            NSString *deviceName = [sim.deviceConfiguration deviceName];
            NSDecimalNumber *simVersion = [sim.osConfiguration versionNumber];
            if ([deviceName containsString:@"iPhone 6s"]) {
                if (candidate) {
                    NSDecimalNumber *candidateVersion = [candidate.osConfiguration versionNumber];
                    if ([simVersion isGreaterThan:candidateVersion]) {
                        candidate = sim;
                    }
                } else {
                    candidate = sim;
                }
            }
        }
        return candidate.udid;
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
