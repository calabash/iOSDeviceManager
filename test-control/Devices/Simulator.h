
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "SimulatorTestParameters.h"
#import "Device.h"
@import Foundation;

@interface Simulator : Device<FBTestManagerTestReporter, FBControlCoreLogger>
+ (BOOL)startTest:(SimulatorTestParameters *)params;
@end
