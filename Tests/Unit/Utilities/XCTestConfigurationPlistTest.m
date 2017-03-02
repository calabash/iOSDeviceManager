
#import "TestCase.h"
#import "XCTestConfigurationPlist.h"

@interface XCTestConfigurationPlistTest : TestCase

@end

@implementation XCTestConfigurationPlistTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testPlistWithTestBundlePath {
    NSString *bundlePath = @"/private/containers/DeviceAgent-Runner.app/PlugIns/DeviceTest.xctest";

    NSString *actual = [XCTestConfigurationPlist plistWithTestBundlePath:bundlePath];

    expect([actual containsString:bundlePath]).to.beTruthy;
    expect([actual containsString:@"TEST_BUNDLE_URL"]).notTo.beTruthy;
}

@end
