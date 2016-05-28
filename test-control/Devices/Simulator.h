
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "SimulatorTestParameters.h"
@import Foundation;

@interface Simulator : NSObject<FBTestManagerTestReporter>
+ (BOOL)startTest:(SimulatorTestParameters *)params;
@end
