
#import "DeviceCLIIntegrationTests.h"

@interface SimulatorCLIIntegrationTests : DeviceCLIIntegrationTests
@end

@implementation SimulatorCLIIntegrationTests

- (void)setUp {
    self.continueAfterFailure = NO;
    self.deviceID = defaultSimUDID;
    self.codesignID = @"-"; //ad hoc
    self.platform = SIM;

    [self launchSim];
    [super setUp];
}

- (void)tearDown {
    [self killSim];
    [super tearDown];
}

- (void)killSim {
    NSArray *args = @[kProgramName, @"kill_simulator", @"-d", self.deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)launchSim {
    NSArray *args = @[kProgramName, @"launch_simulator", @"-d", self.deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testSetLocation {
    [self killSim];
    
    //Should fail: Even though coord is valid, device is dead
    XCTAssertEqual([self setLocation:kStockholmCoord], iOSReturnStatusCodeGenericFailure);

    [self launchSim];
    [self sharedSetLocationTest];
}

- (void)testStopSimulatingLocation {
    //Should essentially be a noop that returns 'EverythingOK
    [self sharedStopSimulatingLocationTest];
}

- (void)testLaunchSim {
    [self launchSim];
}

- (void)testKillSim {
    [self killSim];
}

- (void)testStartTest {
    NSArray *args = @[kProgramName, @"kill_simulator", @"-d", defaultSimUDID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    //Should launch sim
    XCTAssertEqual([self startTest], iOSReturnStatusCodeEverythingOkay);

    //Should work even though sim is already launched
    XCTAssertEqual([self startTest], iOSReturnStatusCodeEverythingOkay);
}

- (void)testUninstall {
    [self sharedUninstallTest];
}

- (void)testInstall {
    [self sharedInstallTest];
}

- (void)testAppIsInstalled {
    [self sharedAppIsInstalledTest];
}


- (void)testAppUpdate {
    [self sharedAppUpdateTest];
}

- (void)testUploadFile {
    [self sharedUploadFileTest];
}

- (void)testOptionalDeviceIDArg {
    if ([DeviceUtils availablePhysicalDevices].count > 0) {
        NSLog(@"Physical device detected - skipping optional device arg tests for simulator");
        return;
    }
    
    [self sharedOptionalArgsTest];
}

- (void)testPositionalArgs {
    [self sharedPositionalArgsTest];
}

- (void)testLaunchAndKillApp {
    if ([DeviceUtils availablePhysicalDevices].count > 0) {
        [self sharedLaunchAndKillAppTest];
    }
}

@end
