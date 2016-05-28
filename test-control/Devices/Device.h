
@import Foundation;
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "DeviceTestParameters.h"

@interface Device : NSObject<FBTestManagerTestReporter, FBControlCoreLogger>
+ (BOOL)startTest:(DeviceTestParameters *)params;
@end
