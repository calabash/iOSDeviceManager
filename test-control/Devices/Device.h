
@import Foundation;
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "DeviceTestParameters.h"

@interface Device : NSObject<FBTestManagerTestReporter>
+ (BOOL)startTest:(DeviceTestParameters *)params;
@end
