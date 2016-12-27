#import <Foundation/Foundation.h>
#import "Device.h"
#import "TestCase.h"

@interface DeviceTest : TestCase

@end

@implementation DeviceTest

- (void)testDefaultSimulator {
    FBSimulator *preferredSim = [Device defaultSimulator:[Device availableSimulators]];
    NSString *preferredName = [preferredSim.deviceConfiguration deviceName];
    expect([preferredName containsString:@"iPhone"]).to.equal(YES);
}

@end
