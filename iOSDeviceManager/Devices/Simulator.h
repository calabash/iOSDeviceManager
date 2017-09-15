#import <XCTestBootstrap/XCTestBootstrap.h>
#import "Device.h"
@import Foundation;

@interface Simulator : Device<FBTestManagerTestReporter, FBControlCoreLogger>

+ (NSURL *)simulatorAppURL;

@end
