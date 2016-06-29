
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "Device.h"
@import Foundation;

@interface Simulator : Device<FBTestManagerTestReporter, FBControlCoreLogger>
+ (iOSReturnStatusCode)launchSimulator:(NSString *)simID;
+ (iOSReturnStatusCode)killSimulator:(NSString *)simID;
@end
