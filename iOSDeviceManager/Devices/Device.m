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

@end
