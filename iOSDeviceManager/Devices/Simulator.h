#import <XCTestBootstrap/XCTestBootstrap.h>
#import "Device.h"
@import Foundation;

@interface Simulator : Device<FBTestManagerTestReporter, FBControlCoreLogger>

+ (NSURL *)simulatorAppURL;

+ (iOSReturnStatusCode)launchSimulator:(Simulator *)simulator;
+ (iOSReturnStatusCode)killSimulatorApp;

@end
