
@import Foundation;
#import "Device.h"
#import <XCTestBootstrap/XCTestBootstrap.h>

@interface PhysicalDevice : Device<FBTestManagerTestReporter, FBControlCoreLogger>
+ (iOSReturnStatusCode)stopSimulatingLocation:(NSString *)deviceID;
+ (iOSReturnStatusCode)containerPathForApplication:(NSString *)bundleID
                                          onDevice:(NSString *)deviceID;
@end
