
@import Foundation;
#import "Device.h"
#import <XCTestBootstrap/XCTestBootstrap.h>

@interface PhysicalDevice : Device<FBTestManagerTestReporter, FBControlCoreLogger>
+ (iOSReturnStatusCode)stopSimulatingLocation:(NSString *)deviceID;
+ (iOSReturnStatusCode)uploadFiles:(NSArray<NSString *> *)filenames
                          toDevice:(NSString *)deviceID
                    forApplication:(NSString *)bundleID;
@end
