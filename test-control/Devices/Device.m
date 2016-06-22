
#import "PhysicalDevice.h"
#import "Simulator.h"

@implementation Device
+ (BOOL)startTest:(TestParameters *)params {
    if (params.deviceType == kDeviceTypeDevice) {
        return [PhysicalDevice startTest:params.asDeviceTestParameters];
    } else {
        return [Simulator startTest:params.asSimulatorTestParameters];
    }
}

+ (BOOL)installApp:(NSString *)pathToBundle
          deviceID:(NSString *)deviceID
        codesignID:(NSString *)codesignID {
    if ([TestParameters isDeviceID:deviceID]) {
        return [PhysicalDevice installApp:pathToBundle
                                 deviceID:deviceID
                               codesignID:codesignID];
    } else {
        return [Simulator installApp:pathToBundle
                            deviceID:deviceID
                          codesignID:nil];
    }
}

+ (BOOL)uninstallApp:(NSString *)bundleID
            deviceID:(NSString *)deviceID {
    if ([TestParameters isSimulatorID:deviceID]) {
        return [Simulator uninstallApp:bundleID deviceID:deviceID];
    } else {
        return [PhysicalDevice uninstallApp:bundleID deviceID:deviceID];
    }
}

+ (int)appIsInstalled:(NSString *)bundleID
              deviceID:(NSString *)deviceID {
    if ([TestParameters isSimulatorID:deviceID]) {
        return [Simulator appIsInstalled:bundleID deviceID:deviceID];
    } else {
        return [PhysicalDevice appIsInstalled:bundleID deviceID:deviceID];
    }
}

+ (BOOL)clearAppData:(NSString *)bundleID
            deviceID:(NSString *)deviceID {
    if ([TestParameters isSimulatorID:deviceID]) {
        return [Simulator clearAppData:bundleID deviceID:deviceID];
    } else {
        return [PhysicalDevice clearAppData:bundleID deviceID:deviceID];
    }
}

@end
