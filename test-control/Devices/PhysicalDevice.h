
@import Foundation;
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "DeviceTestParameters.h"
#import "Device.h"

@interface PhysicalDevice : Device<FBTestManagerTestReporter, FBControlCoreLogger>
+ (BOOL)startTest:(DeviceTestParameters *)params;
@end
