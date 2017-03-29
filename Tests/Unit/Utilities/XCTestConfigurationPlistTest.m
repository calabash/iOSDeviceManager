
#import "TestCase.h"
#import "XCTestConfigurationPlist.h"

@interface XCTestConfigurationPlist (TEST)

+ (BOOL)xcodeVersionIsGreaterThanEqualTo83:(NSDecimalNumber *)activeXcodeVersion;

@end

@interface XCTestConfigurationPlistTest : TestCase

@end

@implementation XCTestConfigurationPlistTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testPlistWithTestBundlePathReplacesTEST_BUNDLE_URL {
    NSString *bundlePath = @"/private/containers/DeviceAgent-Runner.app/PlugIns/DeviceTest.xctest";

    NSString *actual = [XCTestConfigurationPlist plistWithTestBundlePath:bundlePath];

    expect([actual containsString:bundlePath]).to.beTruthy;
    expect([actual containsString:@"TEST_BUNDLE_URL"]).notTo.beTruthy;
}

- (void)testXcodeVersionIsGreaterThanEqualTo83 {

    NSDecimalNumber *xcodeVersion;
    BOOL actual;

    // returns true for Xcode 8.3
    xcodeVersion = [NSDecimalNumber decimalNumberWithString:@"8.3"];
    actual = [XCTestConfigurationPlist xcodeVersionIsGreaterThanEqualTo83:xcodeVersion];
    expect(actual).to.beTruthy;

    // returns true for Xcode > 8.3
    xcodeVersion = [NSDecimalNumber decimalNumberWithString:@"8.3.1"];
    actual = [XCTestConfigurationPlist xcodeVersionIsGreaterThanEqualTo83:xcodeVersion];
    expect(actual).to.beTruthy;

    // returns false for Xcode < 8.3
    xcodeVersion = [NSDecimalNumber decimalNumberWithString:@"8.2.1"];
    actual = [XCTestConfigurationPlist xcodeVersionIsGreaterThanEqualTo83:xcodeVersion];
    expect(actual).notTo.beTruthy;
}

@end
