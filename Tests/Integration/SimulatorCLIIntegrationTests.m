
#import "TestCase.h"
#import "Device.h"
#import "CLI.h"
#import "DeviceUtils.h"
#import "Simulator.h"
#import "Application.h"

@interface CLI (priv)
@end

@implementation CLI (priv)
@end

@interface Simulator (TEST)

- (BOOL)boot;

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
    expect([Simulator killSimulatorApp]).to.equal(iOSReturnStatusCodeEverythingOkay);
    expect([simulator boot]).to.beTruthy();

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
