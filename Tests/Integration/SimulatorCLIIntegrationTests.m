
#import "TestCase.h"
#import "Device.h"
#import "CLI.h"
#import "DeviceUtils.h"

@interface CLI (priv)
@end

@implementation CLI (priv)
@end


@interface SimulatorCLIIntegrationTests : TestCase

- (NSString *)bundleVersionForInstalledTestApp;

@end

@implementation SimulatorCLIIntegrationTests

- (void)setUp {
    self.continueAfterFailure = NO;
    [super setUp];
}

- (NSString *)bundleVersionForInstalledTestApp {
    NSDictionary *plist;
    plist = [[Device withID:defaultSimUDID] installedApp:testAppID].infoPlist;
    return plist[@"CFBundleVersion"];
}

- (void)testSetLocation {
    NSArray *args = @[kProgramName, @"kill_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    //Should fail: device is dead
    args = @[kProgramName, @"set_location", @"-d", defaultSimUDID, @"-l", kStockholmCoord];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);

    args = @[kProgramName, @"launch_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    //Should fail: invalid coordinates
    args = @[kProgramName, @"set_location", @"-d", defaultSimUDID, @"-l", @"Banana"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInvalidArguments);

    args = @[kProgramName, @"set_location", @"-d", defaultSimUDID, @"-l", kStockholmCoord];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testLaunchSim {
    NSArray *args = @[kProgramName, @"launch_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testKillSim {
    NSArray *args = @[kProgramName, @"kill_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

// Causes deadlock when run with other tests.
//
//- (void)testStartTest {
//    NSArray *args = @[kProgramName, @"kill_simulator", @"-d", defaultSimUDID];
//    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
//
//    //Should launch sim
//    args = @[kProgramName, @"start_test",
//             @"-d", defaultSimUDID,
//             @"-k", @"NO"];
//    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
//
//    args = @[kProgramName, @"start_test",
//             @"-d", defaultSimUDID,
//             @"-k", @"NO"];
//    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
//}

- (void)testUninstall {
    NSArray *args = @[kProgramName, @"kill_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"uninstall", @"-d", defaultSimUDID, @"-b", testAppID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);

    args = @[kProgramName, @"launch_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"is_installed", @"-b", testAppID, @"-d", defaultSimUDID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[kProgramName, @"install", @"-d", defaultSimUDID, @"-a",
                 [self.resources TestAppPath:SIM]];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }

    args = @[kProgramName, @"uninstall", @"-d", defaultSimUDID, @"-b", testAppID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testInstall {
    NSArray *args = @[kProgramName, @"kill_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"launch_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"is_installed", @"-b", taskyAppID, @"-d", defaultSimUDID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[kProgramName, @"uninstall", @"-d", defaultSimUDID, @"-b", taskyAppID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }

    args = @[kProgramName, @"install", @"-d", defaultSimUDID, @"-a", tasky(SIM)];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testAppIsInstalled {
    NSArray *args = @[kProgramName, @"kill_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"launch_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"is_installed", @"-b", @"com.apple.Preferences", @"-d",
             defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"is_installed", @"-b", testAppID, @"-d", defaultSimUDID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[kProgramName, @"uninstall", @"-d", defaultSimUDID, @"-b", testAppID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }

    args = @[kProgramName, @"is_installed", @"-b", testAppID, @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeFalse);

    args = @[kProgramName, @"install", @"-d", defaultSimUDID, @"-a", testApp(SIM)];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"is_installed", @"-b", testAppID, @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}


- (void)testAppUpdate {
    NSArray *args = @[kProgramName, @"kill_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"launch_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    //Ensure app is not installed
    args = @[kProgramName, @"is_installed", @"-b", testAppID, @"-d", defaultSimUDID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[kProgramName, @"uninstall", @"-d", defaultSimUDID, @"-b", testAppID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }

    //Set app's info.plist CFBundleVersion to 1.0
    NSString *tmpDir = [self.resources uniqueTmpDirectory];
    NSString *source = testApp(SIM);
    NSString *target = [tmpDir stringByAppendingPathComponent:[source lastPathComponent]];
    [self.resources copyDirectoryWithSource:source target:target];

    XCTAssertTrue([self.resources updatePlistForBundle:target
                                                   key:@"CFBundleVersion"
                                                 value:@"1.0"]);

    args = @[kProgramName, @"install", @"-d", defaultSimUDID, @"-a", target];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    //Ensure that the installed app has CFBundleVersion 1.0
    NSString *installedVersion = [self bundleVersionForInstalledTestApp];
    XCTAssertEqualObjects(installedVersion, @"1.0",
                          @"Installed app's Info.plist doesn't match");

    //Now update the local plist to have CFBundleVersion 2.0
    XCTAssertTrue([self.resources updatePlistForBundle:target
                                                   key:@"CFBundleVersion"
                                                 value:@"2.0"]);

    //Install the app and ensure that the new version has been installed
    args = @[kProgramName, @"install", @"-d", defaultSimUDID, @"-a", target];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    installedVersion = [self bundleVersionForInstalledTestApp];
    XCTAssertEqualObjects(installedVersion, @"2.0",
                          @"Installed app's Info.plist doesn't match");


    //Now change it back to 1.0 and try to install while setting `-u` to false.
    //We should see that the installed version remains at 2.0
    XCTAssertTrue([self.resources updatePlistForBundle:target
                                                   key:@"CFBundleVersion"
                                                 value:@"1.0"]);

    args = @[kProgramName, @"install", @"-d", defaultSimUDID, @"-a", target, @"-u", @"NO"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    installedVersion = [self bundleVersionForInstalledTestApp];
    XCTAssertEqualObjects(installedVersion, @"2.0",
                          @"App was updated even though -u was set to NO");
}

- (void)testUploadFile {
    NSArray *args = @[kProgramName, @"kill_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"launch_simulator", @"-d", defaultSimUDID];
    iOSReturnStatusCode launchSimResult;
    
    for (int i = 1; i <= 30; i++) {
        launchSimResult = [CLI process:args];
        if (launchSimResult == iOSReturnStatusCodeInternalError) {
            [NSThread sleepForTimeInterval:1.0f];
        } else {
            break;
        }
    }
    
    XCTAssertEqual(launchSimResult, iOSReturnStatusCodeEverythingOkay);
    
    //Ensure app not installed
    args = @[
             kProgramName, @"is_installed",
             @"-b", testAppID,
             @"-d", defaultSimUDID
             ];
    
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[
                 kProgramName, @"uninstall",
                 @"-b", testAppID,
                 @"-d", defaultSimUDID,
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[
             kProgramName, @"install",
             @"-d", defaultSimUDID,
             @"-a", testApp(SIM),
             @"-c", kCodeSignIdentityKARL
             ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    //Upload a unique file
    NSString *file = uniqueFile();
    args = @[
             kProgramName, @"upload",
             @"-b", testAppID,
             @"-d", defaultSimUDID,
             @"-f", file,
             @"-o", @"NO"
             ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    //Now attempt to overwrite with -o false
    args = @[
             kProgramName, @"upload",
             @"-b", testAppID,
             @"-d", defaultSimUDID,
             @"-f", file,
             @"-o", @"NO"
             ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);
    
    //Now attempt to overwrite with -o true
    args = @[
             kProgramName, @"upload",
             @"-b", testAppID,
             @"-d", defaultSimUDID,
             @"-f", file,
             @"-o", @"YES"
             ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testOptionalDeviceIDArg {
    XCTAssertTrue([DeviceUtils isSimulatorID:[Device defaultDeviceID]], @"Must unplug devices before running!");
    NSArray *args = @[kProgramName, @"kill_simulator"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"launch_simulator"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"is_installed", @"-b", testAppID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[kProgramName, @"uninstall", @"-b", testAppID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[kProgramName, @"install", @"-a", testApp(SIM)];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testPositionalArgs {
    XCTAssertTrue([DeviceUtils isSimulatorID:[Device defaultDeviceID]], @"Must unplug devices before running!");
    NSArray *args = @[kProgramName, @"kill_simulator"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"launch_simulator"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"is_installed", @"-b", testAppID];
    if ([CLI process:args]) {
        args = @[kProgramName, @"uninstall", @"-b", testAppID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[kProgramName, @"install", testApp(SIM), [Device defaultDeviceID]];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"is_installed", @"-b", testAppID];
    if ([CLI process:args]) {
        args = @[kProgramName, @"uninstall", @"-b", testAppID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[kProgramName, @"install", [Device defaultDeviceID], testApp(SIM)];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"install", testApp(SIM)];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"install", [Device defaultDeviceID]];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

@end
