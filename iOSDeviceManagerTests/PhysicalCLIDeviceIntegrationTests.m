
#import "TestCommon.h"
#import "CLI.h"

@interface PhysicalDeviceCLIIntegrationTests : XCTestCase
@end

@implementation PhysicalDeviceCLIIntegrationTests

- (void)setUp {
    setenv("DEVELOPER_DIR", "/Users/chrisf/Xcodes/8b2/Xcode-beta.app/Contents/Developer", YES);
}

- (void)testStartTest {
    NSArray *args = @[progname, @"start_test",
                      @"-d", deviceID,
                      @"-t", deviceTestBundlePath,
                      @"-r", deviceTestRunnerPath,
                      @"-c", codesignIdentity,
                      @"-k", @"NO"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testUninstall {
    NSArray *args = @[progname, @"is_installed", @"-b", unitTestAppID, @"-d", deviceID];
    if ([CLI process:args] == iOSReturnStatusCodeFalse) {
        args = @[progname, @"install", @"-d", deviceID, @"-a", unitTestAppPath, @"-c", codesignIdentity];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[progname, @"uninstall", @"-d", deviceID, @"-b", unitTestAppID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testInstall {
    NSArray *args = @[progname, @"is_installed", @"-b", unitTestAppID, @"-d", deviceID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[progname, @"uninstall", @"-d", deviceID, @"-b", unitTestAppID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[progname, @"install", @"-d", deviceID, @"-a", unitTestIpaPath, @"-c", codesignIdentity];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testAppIsInstalled {
    NSArray *args = @[progname, @"is_installed", @"-b", @"com.apple.Preferences", @"-d", deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"is_installed", @"-b", unitTestAppID, @"-d", deviceID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[progname, @"uninstall", @"-d", deviceID, @"-b", unitTestAppID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[progname, @"is_installed", @"-b", unitTestAppID, @"-d", deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeFalse);
    
    args = @[progname, @"install", @"-d", deviceID, @"-a", unitTestIpaPath, @"-c", codesignIdentity];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"is_installed", @"-b", unitTestAppID, @"-d", deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

@end
