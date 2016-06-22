
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
@end
