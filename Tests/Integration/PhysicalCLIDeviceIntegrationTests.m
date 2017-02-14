
#import "DeviceCLIIntegrationTests.h"

@interface PhysicalDeviceCLIIntegrationTests : DeviceCLIIntegrationTests
@end

@implementation PhysicalDeviceCLIIntegrationTests

- (void)setUp {
    self.deviceID = defaultDeviceUDID;
    [super setUp];
}

//TODO: -k @"YES"; Sleep; POST 1.0/shutdown
- (void)testStartTest {
    if (device_available()) {
        NSArray *args = @[
                kProgramName, @"start_test",
                @"-d", self.deviceID,
                @"-k", @"NO"
        ];

        [CLI process:args];
    }
}

- (void)testSetLocation {
    if (device_available()) {
        //Should fail: invalid coordinates
        NSArray *args = @[
                          kProgramName, @"set_location",
                          @"-d", self.deviceID,
                          @"-l", @"Banana"
                          ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInvalidArguments);

        args = @[
                 kProgramName, @"set_location",
                 @"-d", self.deviceID,
                 @"-l", kStockholmCoord
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testStopSimulatingLocation {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"stop_simulating_location",
                          @"-d", self.deviceID
                          ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testUninstall {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"is_installed",
                          @"-b", testApp(ARM),
                          @"-d", self.deviceID
                          ];
        if ([CLI process:args] == iOSReturnStatusCodeFalse) {
            args = @[kProgramName, @"install",
                     @"-d", self.deviceID,
                     @"-a", testApp(ARM),
                     @"-c", kCodeSignIdentityKARL];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }

        args = @[
                 kProgramName, @"uninstall",
                 @"-d", self.deviceID,
                 @"-b", testAppID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testInstall {
    if (device_available()) {
        [self ensureUninstalled:testAppID];
        
        NSArray *args = @[
                 kProgramName, @"install",
                 @"-d", self.deviceID,
                 @"-a", testApp(ARM),
                 @"-c", kCodeSignIdentityKARL
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testPositionalInstall {
    if (device_available()) {
        [self ensureUninstalled:testAppID];
        
        NSArray *args = @[
                          kProgramName, @"install",
                          self.deviceID,
                          testApp(ARM),
                          @"-c", kCodeSignIdentityKARL
                          ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testAppIsInstalled {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"is_installed",
                          @"-b", @"com.apple.Preferences",
                          @"-d", self.deviceID
                          ];

        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        args = @[
                 kProgramName, @"is_installed",
                 @"-b", testAppID,
                 @"-d", self.deviceID
                 ];

        if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
            args = @[
                     kProgramName, @"uninstall",
                     @"-d", self.deviceID,
                     @"-b", testAppID
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }

        args = @[
                 kProgramName, @"is_installed",
                 @"-b", testAppID,
                 @"-d", self.deviceID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeFalse);

        args = @[
                 kProgramName, @"install",
                 @"-d", self.deviceID,
                 @"-a", testApp(ARM),
                 @"-c", kCodeSignIdentityKARL
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        args = @[
                 kProgramName, @"is_installed",
                 @"-b", testAppID,
                 @"-d", self.deviceID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testUploadFile {
    if (device_available()) {
        //Ensure app installed
        NSArray *args = @[
                          kProgramName, @"is_installed",
                          @"-b", testAppID,
                          @"-d", self.deviceID
                          ];
        
        if ([CLI process:args] == iOSReturnStatusCodeFalse) {
            args = @[
                     kProgramName, @"install",
                     @"-d", self.deviceID,
                     @"-a", testApp(ARM),
                     @"-c", kCodeSignIdentityKARL
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }
        
        //Upload a unique file
        NSString *file = uniqueFile();
        args = @[
                 kProgramName, @"upload",
                 @"-b", testAppID,
                 @"-d", self.deviceID,
                 @"-f", file,
                 @"-o", @"NO"
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        
        //Now attempt to overwrite with -o false
        args = @[
                 kProgramName, @"upload",
                 @"-b", testAppID,
                 @"-d", self.deviceID,
                 @"-f", file,
                 @"-o", @"NO"
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);
        
        //Now attempt to overwrite with -o true
        args = @[
                 kProgramName, @"upload",
                 @"-b", testAppID,
                 @"-d", self.deviceID,
                 @"-f", file,
                 @"-o", @"YES"
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testOptionalDeviceIDArg {
    NSUInteger deviceCount = [DeviceUtils availableDevices].count;
    if (deviceCount != 1) {
        printf("Multiple devices detected - skipping option device arg test");
        return;
    }
    
    NSArray *args = @[
                      kProgramName, @"is_installed",
                      @"-b", testAppID
                      ];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[
                 kProgramName, @"uninstall",
                 @"-b", testAppID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[
             kProgramName, @"install",
             @"-a", testApp(ARM),
             @"-c", kCodeSignIdentityKARL
             ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testLaunchAndKillApp {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"is_installed",
                          @"-b", testAppID,
                          @"-d", self.deviceID
                          ];
        
        if ([CLI process:args] == iOSReturnStatusCodeFalse) {
            args = @[
                     kProgramName, @"install",
                     @"-b", testAppID,
                     @"-d", self.deviceID
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }
        
        args = @[
                 kProgramName, @"launch_app",
                 @"-b", testAppID,
                 @"-d", self.deviceID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        
        //TODO: Verify app is running
        
        args = @[
                 kProgramName, @"kill_app",
                 @"-b", testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

@end
