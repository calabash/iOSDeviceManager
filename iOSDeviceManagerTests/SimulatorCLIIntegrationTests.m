
#import "iOSDeviceManagement.h"
#import <XCTest/XCTest.h>
#import "TestCommon.h"
#import "Device.h"
#import "CLI.h"

@interface SimulatorCLIIntegrationTests : XCTestCase

@end

@implementation SimulatorCLIIntegrationTests

- (void)setUp {
    setenv("DEVELOPER_DIR", "/Users/chrisf/Xcodes/8b2/Xcode-beta.app/Contents/Developer", YES);
    self.continueAfterFailure = NO;
    [super setUp];
}

- (void)testSetLocation {
    NSArray *args = @[progname, @"kill_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    //Should fail: device is dead
    args = @[progname, @"set_location", @"-d", simID, @"-l", Stockholm];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);
    
    args = @[progname, @"launch_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    //Should fail: invalid latlng
    args = @[progname, @"set_location", @"-d", simID, @"-l", @"Banana"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInvalidArguments);
    
    args = @[progname, @"set_location", @"-d", simID, @"-l", Stockholm];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testLaunchSim {
    NSArray *args = @[progname, @"launch_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testKillSim {
    NSArray *args = @[progname, @"kill_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testStartTest {
    NSArray *args = @[progname, @"kill_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    //Should launch sim
    args = @[progname, @"start_test",
             @"-d", simID,
             @"-t", simTestBundlePath,
             @"-r", testAppRunnerPath,
             @"-u", @"YES",
             @"-k", @"NO"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"start_test",
             @"-d", simID,
             @"-t", simTestBundlePath,
             @"-r", testAppRunnerPath,
             @"-u", @"YES",
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

- (void)testAppUpdate {
    NSArray *args = @[progname, @"kill_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"launch_simulator", @"-d", simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    //Ensure app is not installed
    args = @[progname, @"is_installed", @"-b", unitTestAppID, @"-d", simID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[progname, @"uninstall", @"-d", simID, @"-b", unitTestAppID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    //Set app's info.plist CFBundleVersion to 1.0
    NSString *localPlistPath = [unitTestAppPath stringByAppendingPathComponent:@"Info.plist"];
    NSMutableDictionary *appPlist = [NSMutableDictionary dictionaryWithContentsOfFile:localPlistPath];
    XCTAssertNotNil(appPlist, @"No Info.plist found at %@", localPlistPath);
    
    appPlist[@"CFBundleVersion"] = @"1.0";
    XCTAssertTrue([appPlist writeToFile:localPlistPath atomically:YES],
                  @"Unable to write Info.plist to %@",
                  localPlistPath);
    
    args = @[progname, @"install", @"-d", simID, @"-a", unitTestAppPath];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    //Ensure that the installed app has CFBundleVersion 1.0
    NSDictionary *installedPlist = [Device infoPlistForInstalledBundleID:(NSString *)unitTestAppID
                                                                deviceID:(NSString *)simID];
    XCTAssertTrue([installedPlist[@"CFBundleVersion"] isEqual:@"1.0"],
                   @"Installed app's Info.plist doesn't match");
    
    //Now update the local plist to have CFBundleVersion 2.0
    appPlist[@"CFBundleVersion"] = @"2.0";
    XCTAssertTrue([appPlist writeToFile:localPlistPath atomically:YES],
                  @"Unable to write Info.plist to %@",
                  localPlistPath);
    
    //Install the app and ensure that the new version has been installed
    args = @[progname, @"install", @"-d", simID, @"-a", unitTestAppPath];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    installedPlist = [Device infoPlistForInstalledBundleID:(NSString *)unitTestAppID
                                                  deviceID:(NSString *)simID];
    
    XCTAssertTrue([installedPlist[@"CFBundleVersion"] isEqual:@"2.0"],
                   @"Installed app's Info.plist doesn't match");
    
    //Now change it back to 1.0 and try to install while setting `-u` to false.
    //We should see that the installed version remains at 2.0
    appPlist[@"CFBundleVersion"] = @"1.0";
    XCTAssertTrue([appPlist writeToFile:localPlistPath atomically:YES],
                  @"Unable to write Info.plist to %@",
                  localPlistPath);
    
    args = @[progname, @"install", @"-d", simID, @"-a", unitTestAppPath, @"-u", @"NO"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    installedPlist = [Device infoPlistForInstalledBundleID:(NSString *)unitTestAppID
                                                  deviceID:(NSString *)simID];
    
    XCTAssertTrue([installedPlist[@"CFBundleVersion"] isEqual:@"2.0"],
                   @"App was updated even though -u was set to NO");
}


@end
