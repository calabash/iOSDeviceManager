
#import "DeviceTestParameters.h"
#import "Device.h"
#import <XCTest/XCTest.h>

@interface IntegrationTests : XCTestCase

@end

@implementation IntegrationTests

//TODO: Read from env or something
static NSString *simulatorTestBundlePath = @"/Users/chrisf/calabash-xcuitest-server/Products/app/CBX-Runner.app/PlugIns/CBX.xctest";
static NSString *simulatorTestRunnerPath = @"/Users/chrisf/calabash-xcuitest-server/Products/app/CBX-Runner.app";
static NSString *simulatorID = @"334B1CE8-327B-448E-B395-0538674729F7";

static NSString *deviceID = @"49a29c9e61998623e7909e35e8bae50dd07ef85f";
static NSString *deviceTestBundlePath = @"/Users/chrisf/calabash-xcuitest-server/Products/ipa/CBX-Runner.app/PlugIns/CBX.xctest";
static NSString *deviceTestRunnerPath = @"/Users/chrisf/calabash-xcuitest-server/Products/ipa/CBX-Runner.app";
static NSString *codesignIdentity = @"iPhone Developer: Chris Fuentes (<SNIP>)";

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testPhysicalDevice {
    TestParameters *params = [TestParameters fromJSON:@{
                                                        DEVICE_ID_FLAG : deviceID,
                                                        XCTEST_BUNDLE_PATH_FLAG : deviceTestBundlePath,
                                                        TEST_RUNNER_PATH_FLAG : deviceTestRunnerPath,
                                                        CODESIGN_IDENTITY_FLAG : codesignIdentity
                                                        }];
    [Device startTest:params];
}

- (void)testSimulator {
    TestParameters *params = [TestParameters fromJSON:@{
                                                        DEVICE_ID_FLAG : simulatorID,
                                                        XCTEST_BUNDLE_PATH_FLAG : simulatorTestBundlePath,
                                                        TEST_RUNNER_PATH_FLAG : simulatorTestRunnerPath
                                                        }];
    [Device startTest:params];
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
