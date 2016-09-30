
@import Foundation;
#import "Device.h"
#import <XCTestBootstrap/XCTestBootstrap.h>

@interface PhysicalDevice : Device<FBTestManagerTestReporter, FBControlCoreLogger>
+ (iOSReturnStatusCode)stopSimulatingLocation:(NSString *)deviceID;
+ (iOSReturnStatusCode)launchApp:(NSString *)bundleID appArgs:(NSString *)appArgs appEnv:(NSString *)appEnv deviceID:(NSString *)deviceID;
+ (iOSReturnStatusCode)killApp:(NSString *)bundleID deviceID:(NSString *)deviceID;
@end
