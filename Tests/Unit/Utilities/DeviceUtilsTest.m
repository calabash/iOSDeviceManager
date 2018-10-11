#import <Foundation/Foundation.h>
#import "DeviceUtils.h"
#import "TestCase.h"

@interface DeviceUtilsTest : TestCase

@end

@implementation DeviceUtilsTest

- (void)testDefaultSimulator {
    FBSimulator *preferredSim = [DeviceUtils defaultSimulator];
    NSString *preferredName = [preferredSim name];
    expect([preferredName containsString:@"iPhone"]).to.equal(YES);
}

@end
