
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
@end
