#import <Foundation/Foundation.h>
#import "Device.h"
#import "TestCase.h"

@interface DeviceTest : TestCase

@end

@implementation DeviceTest

- (void)testPreferredSimulator {
    FBSimulator *preferredSim = [Device preferredSimulator:[Device availableSimulators]];
    NSString *preferredName = [preferredSim.deviceConfiguration deviceName];
    expect([preferredName containsString:@"iPhone"]).to.equal(YES);
}

@end
