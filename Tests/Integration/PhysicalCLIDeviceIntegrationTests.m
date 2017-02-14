
#import "DeviceCLIIntegrationTests.h"

@interface PhysicalDeviceCLIIntegrationTests : DeviceCLIIntegrationTests
@end

@implementation PhysicalDeviceCLIIntegrationTests

- (void)setUp {
    self.deviceID = defaultDeviceUDID;
    self.codesignID = kCodeSignIdentityKARL;
    self.platform = ARM;
    
    [super setUp];
}

- (void)testStartTest {
    if (device_available()) {
        XCTAssertEqual([self startTest], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testSetLocation {
    if (device_available()) {
        [self sharedSetLocationTest];
    }
}

- (void)testStopSimulatingLocation {
    if (device_available()) {
        [self sharedStopSimulatingLocationTest];
    }
}

- (void)testUninstall {
    if (device_available()) {
        [self sharedUninstallTest];
    }
}

- (void)testInstall {
    if (device_available()) {
        [self sharedInstallTest];
    }
}

- (void)testAppIsInstalled {
    if (device_available()) {
        [self sharedAppIsInstalledTest];
    }
}

- (void)testUploadFile {
    if (device_available()) {
        [self sharedUploadFileTest];
    }
}

- (void)testPositionalArgs {
    if (device_available()) {
        [self sharedPositionalArgsTest];
    }
}

- (void)testOptionalDeviceIDArg {
    NSUInteger deviceCount = [DeviceUtils availableDevices].count;
    if (deviceCount != 1) {
        printf("Multiple devices detected - skipping option device arg test");
        return;
    }
    
    [self sharedOptionalArgsTest];
}

- (void)testLaunchAndKillApp {
    if (device_available()) {
        [self sharedLaunchAndKillAppTest];
    }
}

@end
