#import <Foundation/Foundation.h>
#import "DeviceUtils.h"
#import "TestCase.h"

@interface DeviceUtilsTest : TestCase

@end

@implementation DeviceUtilsTest

- (void)testDefaultSimulator {
    NSString *preferredName = [DeviceUtils defaultSimulator];
    expect([preferredName containsString:@"iPhone"]).to.equal(YES);
}

@end
