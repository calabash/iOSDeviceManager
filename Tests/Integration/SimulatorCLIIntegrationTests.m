
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
