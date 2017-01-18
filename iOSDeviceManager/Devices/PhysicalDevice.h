
@import Foundation;
#import "Device.h"
#import <XCTestBootstrap/XCTestBootstrap.h>

@interface PhysicalDevice : Device<FBTestManagerTestReporter, FBControlCoreLogger>
@end
