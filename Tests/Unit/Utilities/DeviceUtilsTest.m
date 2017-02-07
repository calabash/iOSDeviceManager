#import <Foundation/Foundation.h>
#import "DeviceUtils.h"
#import "TestCase.h"

@interface DeviceUtilsTest : TestCase

@end

@implementation DeviceUtilsTest

- (void)testDefaultSimulator {
    FBSimulator *preferredSim = [DeviceUtils defaultSimulator:[DeviceUtils availableSimulators]];
    NSString *preferredName = [preferredSim.deviceConfiguration deviceName];
    expect([preferredName containsString:@"iPhone"]).to.equal(YES);
}

@end
