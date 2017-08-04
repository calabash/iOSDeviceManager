
#import "TestCase.h"
#import "Device.h"
#import "CLI.h"
#import "DeviceUtils.h"
#import "Simulator.h"

@interface CLI (priv)
@end

@implementation CLI (priv)
@end

@interface Simulator (TEST)

- (BOOL)bootIfNecessary:(NSError * __autoreleasing *) error;
- (BOOL)waitForBootableState:(NSError *__autoreleasing *)error;

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
    NSArray *args = @[kProgramName, @"kill-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    //Should fail: device is dead
    args = @[kProgramName, @"set-location", kStockholmCoord, @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);

    args = @[kProgramName, @"launch-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    //Should fail: invalid coordinates
    args = @[kProgramName, @"set-location", @"Banana", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInvalidArguments);

    args = @[kProgramName, @"set-location", kStockholmCoord, @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testLaunchSim {
    NSArray *args = @[kProgramName, @"launch-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testKillSim {
    NSArray *args = @[kProgramName, @"kill-simulator", @"-d", defaultSimUDID];
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
    NSArray *args = @[kProgramName, @"kill-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"uninstall", testAppID, @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);

    args = @[kProgramName, @"launch-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"is-installed", testAppID, @"-d", defaultSimUDID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[kProgramName, @"install", [self.resources TestAppPath:SIM], @"-d", defaultSimUDID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }

    args = @[kProgramName, @"uninstall", testAppID, @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testInstall {
    NSArray *args = @[kProgramName, @"kill-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"launch-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"is-installed", taskyAppID, @"-d", defaultSimUDID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[kProgramName, @"uninstall", taskyAppID, @"-d", defaultSimUDID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }

    args = @[kProgramName, @"install", tasky(SIM), @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"is-installed", taskyAppID, @"-d", defaultSimUDID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[kProgramName, @"uninstall", taskyAppID, @"-d", defaultSimUDID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testAppInfo {
    NSArray *args = @[kProgramName, @"kill-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"launch-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"is-installed", taskyAppID, @"-d", defaultSimUDID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[kProgramName, @"uninstall", taskyAppID, @"-d", defaultSimUDID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }

    args = @[kProgramName, @"install", tasky(SIM), @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"app-info", taskyAppID, @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testAppIsInstalled {
    NSArray *args = @[kProgramName, @"kill-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"launch-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"is-installed", @"com.apple.Preferences", @"-d",
             defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"is-installed", testAppID, @"-d", defaultSimUDID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[kProgramName, @"uninstall", testAppID, @"-d", defaultSimUDID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }

    args = @[kProgramName, @"is-installed", testAppID, @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeFalse);

    args = @[kProgramName, @"install", testApp(SIM), @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"is-installed", testAppID, @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}


- (void)testAppUpdate {
    NSArray *args = @[kProgramName, @"kill-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"launch-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    //Ensure app is not installed
    args = @[kProgramName, @"is-installed", testAppID, @"-d", defaultSimUDID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[kProgramName, @"uninstall", testAppID, @"-d", defaultSimUDID];
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

    args = @[kProgramName, @"install", target, @"-d", defaultSimUDID];
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
    args = @[kProgramName, @"install", target, @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    installedVersion = [self bundleVersionForInstalledTestApp];
    XCTAssertEqualObjects(installedVersion, @"2.0",
                          @"Installed app's Info.plist doesn't match");


    //Now change it back to 1.0 and try to install while setting `-u` to false.
    //We should see that the installed version remains at 2.0
    XCTAssertTrue([self.resources updatePlistForBundle:target
                                                   key:@"CFBundleVersion"
                                                 value:@"1.0"]);

    args = @[kProgramName, @"install", target, @"-d", defaultSimUDID, @"-u", @"NO"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    installedVersion = [self bundleVersionForInstalledTestApp];
    XCTAssertEqualObjects(installedVersion, @"2.0",
                          @"App was updated even though -u was set to NO");
}

- (void)testUploadFile {
    NSArray *args = @[kProgramName, @"kill-simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"launch-simulator", @"-d", defaultSimUDID];
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
             kProgramName, @"is-installed",
             testAppID,
             @"-d", defaultSimUDID
             ];
    
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[
                 kProgramName, @"uninstall",
                 testAppID,
                 @"-d", defaultSimUDID,
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[
             kProgramName, @"install",
             testApp(SIM),
             @"-d", defaultSimUDID,
             @"-c", kCodeSignIdentityKARL
             ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    //Upload a unique file
    NSString *file = uniqueFile();
    args = @[
             kProgramName, @"upload",
             file,
             testAppID,
             @"-d", defaultSimUDID,
             @"-o", @"NO"
             ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    //Now attempt to overwrite with -o false
    args = @[
             kProgramName, @"upload",
             file,
             testAppID,
             @"-d", defaultSimUDID,
             @"-o", @"NO"
             ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);
    
    //Now attempt to overwrite with -o true
    args = @[
             kProgramName, @"upload",
             file,
             testAppID,
             @"-d", defaultSimUDID,
             @"-o", @"YES"
             ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testPositionalArgs {
    NSString *deviceID = [DeviceUtils defaultSimulatorID];
    NSArray *args = @[kProgramName, @"kill-simulator", @"-d", deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"launch-simulator", @"-d", deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"is-installed", testAppID, @"-d", deviceID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[kProgramName, @"uninstall", testAppID, @"-d", deviceID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[kProgramName, @"install", testApp(SIM), @"-d", deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"is-installed", testAppID, @"-d", deviceID];
    if ([CLI process:args]) {
        args = @[kProgramName, @"uninstall", testAppID, @"-d", deviceID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[kProgramName, @"install", testApp(SIM), @"-d", deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"install", testApp(SIM), @"-d", deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"install", @"-d", deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
    
    args = @[kProgramName, @"install", testApp(SIM), @"-d", deviceID, @"-d", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInvalidArguments);
}

- (void)testLaunchAndKillApp {
    NSArray *args = @[kProgramName, @"kill-simulator", @"-d", [DeviceUtils defaultSimulatorID]];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"launch-simulator", @"-d", [DeviceUtils defaultSimulatorID]];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"is-installed", testAppID, @"-d", [DeviceUtils defaultSimulatorID]];
    if ([CLI process:args] == iOSReturnStatusCodeFalse) {
        args = @[kProgramName, @"install", testApp(SIM), @"-d", [DeviceUtils defaultSimulatorID]];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[kProgramName, @"launch-app", testAppID, @"-d", [DeviceUtils defaultSimulatorID]];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[kProgramName, @"kill-app", testAppID, @"-d", [DeviceUtils defaultSimulatorID]];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testInstallAndInjectResource {

    Application *app = [Application withBundlePath:testApp(SIM)];
    Simulator *simulator = [Simulator withID:defaultSimUDID];

    // --update-app flag is not working, so we must uninstall
    // When injecting resources, we should _always_ reinstall because
    // the version of the resources may have changed?
    expect([simulator kill]).to.equal(iOSReturnStatusCodeEverythingOkay);
    expect([simulator waitForBootableState:nil]).to.beTruthy();
    expect([simulator bootIfNecessary:nil]).to.beTruthy();

    if ([simulator isInstalled:app.bundleID withError:nil]) {
        expect(
               [simulator uninstallApp:app.bundleID]
               ).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    NSString *dylibPath = [[Resources shared] TestRecorderDylibPath];
    NSArray *args = @[kProgramName,
                      @"install",
                      app.path,
                      @"--device-id", simulator.uuid,
                      @"--resources-path", dylibPath
                      ];

    expect([CLI process:args]).to.equal(iOSReturnStatusCodeEverythingOkay);

    expect(
           [simulator launchApp:[app bundleID]]
           ).to.equal(iOSReturnStatusCodeEverythingOkay);

    __block NSString *version = nil;

    [[[FBRunLoopSpinner new] timeout:30] spinUntilTrue:^BOOL{
        version = [[Resources shared] TestRecorderVersionFromHost:@"127.0.0.1"];
        return version != nil;
    }];

    expect(version).to.beTruthy();
}

@end
