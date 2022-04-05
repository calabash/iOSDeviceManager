
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

@property (atomic, strong) Simulator *simulator;
@property (atomic, strong) Application *app;

- (NSString *)bundleVersionForInstalledTestApp;

@end

@implementation SimulatorCLIIntegrationTests

- (void)setUp {
    self.simulator = [Simulator withID:defaultSimUDID];
    self.app = [Application withBundlePath:testApp(SIM)];
    [Simulator killSimulatorApp];
    self.continueAfterFailure = NO;
    [super setUp];
}

- (void)tearDown {
    self.simulator = nil;
    self.app = nil;
    [super tearDown];
}

- (NSString *)bundleVersionForInstalledTestApp {
    NSDictionary *plist;
    plist = [[Device withID:defaultSimUDID] installedApp:testAppID].infoPlist;
    return plist[@"CFBundleVersion"];
}

- (void)testLaunchAndKillApp {
    expect([self.simulator boot]).to.beTruthy();

    if (![self.simulator isInstalled:self.app.bundleID withError:nil]) {
        expect(
               [self.simulator installApp:self.app forceReinstall:true]
               ).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    NSArray *args = @[kProgramName, @"launch-app", testAppID, @"-d", [DeviceUtils defaultSimulatorID]];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"kill-app", testAppID, @"-d", [DeviceUtils defaultSimulatorID]];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testLaunchSimulatorAndKillIt {
    NSArray *args = @[kProgramName, @"launch-simulator", @"-d", [DeviceUtils defaultSimulatorID]];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    args = @[kProgramName, @"kill-simulator", @"-d", [DeviceUtils defaultSimulatorID]];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testInstallAndInjectResource {

    // --update-app flag is not working, so we must uninstall
    // When injecting resources, we should _always_ reinstall because
    // the version of the resources may have changed?
    expect([self.simulator boot]).to.beTruthy();

    if ([self.simulator isInstalled:self.app.bundleID withError:nil]) {
        expect(
               [self.simulator uninstallApp:self.app.bundleID]
               ).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    NSString *dylibPath = [[Resources shared] TestRecorderDylibPath];
    NSArray *args = @[kProgramName,
                      @"install",
                      self.app.path,
                      @"--device-id", self.simulator.uuid,
                      @"--resources-path", dylibPath
                      ];

    expect([CLI process:args]).to.equal(iOSReturnStatusCodeEverythingOkay);

    expect(
           [self.simulator launchApp:[self.app bundleID]]
           ).to.equal(iOSReturnStatusCodeEverythingOkay);

    __block NSString *version = nil;

    [NSRunLoop.currentRunLoop spinRunLoopWithTimeout:30 untilTrue:^BOOL{
        version = [[Resources shared] TestRecorderVersionFromHost:@"127.0.0.1"];
        return version != nil;
    }];

    expect(version).to.beTruthy();
}

@end
