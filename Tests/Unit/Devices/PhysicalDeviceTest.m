
#import "TestCase.h"
#import "PhysicalDevice.h"
#import <FBDeviceControl/FBDeviceControl.h>

@interface FBiOSDeviceOperator (TEST)

+ (NSDictionary *)applicationReturnAttributesDictionary;

@end

@interface PhysicalDeviceTest : TestCase

@end

@implementation PhysicalDeviceTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testFBiOSDeviceOperatorProvidesMethodForApplicationAttributes {
    NSDictionary *dictionary = [FBiOSDeviceOperator applicationReturnAttributesDictionary];
    NSArray *attrs = dictionary[@"ReturnAttributes"];
    expect(attrs).to.contain(@"CFBundleIdentifier");
    expect(attrs).to.contain(@"Path");
    expect(attrs).to.contain(@"Container");
}

@end
