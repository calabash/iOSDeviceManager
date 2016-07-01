
#import "iOSDeviceManagement.h"
#import <XCTest/XCTest.h>
#import "TestCommon.h"
#import "CLI.h"

@interface SimulatorCLIIntegrationTests : XCTestCase

@end

@implementation SimulatorCLIIntegrationTests


- (void)testLaunchSim {
    NSArray *args = @[progname, @"launch_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testKillSim {
    NSArray *args = @[progname, @"kill_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testStartTest {
    NSArray *args = @[progname, @"launch_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    setenv("DEVELOPER_DIR", "/Users/chrisf/Xcodes/8b1/Xcode-beta.app/Contents/Developer", YES);
    args = @[progname, @"start_test",
             @"-d", simID,
             @"-t", simTestBundlePath,
             @"-r", testAppRunnerPath,
             @"-k", @"NO"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testUninstall {
    NSArray *args = @[progname, @"kill_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"uninstall", @"-d", simID, @"-b", unitTestAppID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);
    
    args = @[progname, @"launch_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"is_installed", @"-b", unitTestAppID, @"-d", simID];
    if ([CLI process:args] == iOSReturnStatusCodeFalse) {
        args = @[progname, @"install", @"-d", simID, @"-a", unitTestAppPath];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[progname, @"uninstall", @"-d", simID, @"-b", unitTestAppID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testInstall {
    NSArray *args = @[progname, @"kill_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"launch_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"is_installed", @"-b", taskyID, @"-d", simID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[progname, @"uninstall", @"-d", simID, @"-b", taskyID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[progname, @"install", @"-d", simID, @"-a", taskyPath];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testAppIsInstalled {
    NSArray *args = @[progname, @"kill_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"launch_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"is_installed", @"-b", @"com.apple.Preferences", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"is_installed", @"-b", unitTestAppID, @"-d", simID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[progname, @"uninstall", @"-d", simID, @"-b", unitTestAppID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[progname, @"is_installed", @"-b", unitTestAppID, @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeFalse);

    args = @[progname, @"install", @"-d", simID, @"-a", unitTestAppPath];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"is_installed", @"-b", unitTestAppID, @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}


@end
