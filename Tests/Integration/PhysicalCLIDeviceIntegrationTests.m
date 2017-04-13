
#import "TestCase.h"
#import "CLI.h"
#import "DeviceUtils.h"
#import "CodesignResources.h"

@interface PhysicalDeviceCLIIntegrationTests : TestCase

@end

@implementation PhysicalDeviceCLIIntegrationTests

- (void)setUp {
    [super setUp];
}

/* Hangs indefinitely until a POST 1.0/shutdown is received
- (void)testStartTest {
    if (device_available()) {
        NSArray *args = @[
                kProgramName, @"start_test",
                @"-d", defaultDeviceUDID,
                @"-k", @"YES"
        ];

        [CLI process:args];
    }
}
*/


- (void)testSetLocation {
    if (device_available()) {
        //Should fail: invalid coordinates
        NSArray *args = @[
                          kProgramName, @"set_location",
                          @"-d", defaultDeviceUDID,
                          @"-l", @"Banana"
                          ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInvalidArguments);

        args = @[
                 kProgramName, @"set_location",
                 @"-d", defaultDeviceUDID, @"-l",
                 kStockholmCoord
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testStopSimulatingLocation {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"stop_simulating_location",
                          @"-d", defaultDeviceUDID
                          ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testUninstall {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"is_installed",
                          @"-b", testAppID,
                          @"-d", defaultDeviceUDID
                          ];
        if ([CLI process:args] == iOSReturnStatusCodeFalse) {
            args = @[kProgramName, @"install",
                     @"-d", defaultDeviceUDID,
                     @"-a", testApp(ARM),
                     @"-c", kCodeSignIdentityKARL];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }

        args = @[
                 kProgramName, @"uninstall",
                 @"-d", defaultDeviceUDID,
                 @"-b", testAppID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testInstall {
    if (device_available()) {
            NSArray *args = @[
                              kProgramName, @"is_installed",
                              @"-b", testAppID,
                              @"-d", defaultDeviceUDID
                              ];
            
            if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
                args = @[
                         kProgramName, @"uninstall",
                         @"-d", defaultDeviceUDID,
                         @"-b", testAppID
                         ];
                XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
            }
            
            args = @[
                     kProgramName, @"install",
                     @"-d", defaultDeviceUDID,
                     @"-a", testApp(ARM),
                     @"-c", kCodeSignIdentityKARL
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        // Test installing with injecting resource
        args = @[
                  kProgramName, @"is_installed",
                  @"-b", testAppID,
                  @"-d", defaultDeviceUDID
                ];

        if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
            args = @[
                     kProgramName, @"uninstall",
                     @"-d", defaultDeviceUDID,
                     @"-b", testAppID
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }

        args = @[
                 kProgramName, @"install",
                 @"-d", defaultDeviceUDID,
                 @"-a", testApp(ARM),
                 @"-c", kCodeSignIdentityKARL,
                 @"-i", [CodesignResources CalabashDylibPath]
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        args = @[
                 kProgramName, @"launch_app",
                 @"-d", defaultDeviceUDID,
                 @"-b", testAppID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        [NSThread sleepForTimeInterval:0.5];

        NSError *error;
        int pid = (int)[[[Device withID:defaultDeviceUDID] fbDeviceOperator] processIDWithBundleID:testAppID error:&error];
        XCTAssertTrue(pid > 0);
    }
}

- (void)testAppIsInstalled {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"is_installed",
                          @"-b", @"com.apple.Preferences",
                          @"-d", defaultDeviceUDID
                          ];

        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        args = @[
                 kProgramName, @"is_installed",
                 @"-b", testAppID,
                 @"-d", defaultDeviceUDID
                 ];

        if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
            args = @[
                     kProgramName, @"uninstall",
                     @"-d", defaultDeviceUDID,
                     @"-b", testAppID
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }

        args = @[
                 kProgramName, @"is_installed",
                 @"-b", testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeFalse);

        args = @[
                 kProgramName, @"install",
                 @"-d", defaultDeviceUDID,
                 @"-a", testApp(ARM),
                 @"-c", kCodeSignIdentityKARL
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        args = @[
                 kProgramName, @"is_installed",
                 @"-b", testAppID,
                 @"-d", defaultDeviceUDID
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
                          @"-d", defaultDeviceUDID
                          ];
        
        if ([CLI process:args] == iOSReturnStatusCodeFalse) {
            args = @[
                     kProgramName, @"install",
                     @"-d", defaultDeviceUDID,
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
                 @"-d", defaultDeviceUDID,
                 @"-f", file,
                 @"-o", @"NO"
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        
        //Now attempt to overwrite with -o false
        args = @[
                 kProgramName, @"upload",
                 @"-b", testAppID,
                 @"-d", defaultDeviceUDID,
                 @"-f", file,
                 @"-o", @"NO"
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);
        
        //Now attempt to overwrite with -o true
        args = @[
                 kProgramName, @"upload",
                 @"-b", testAppID,
                 @"-d", defaultDeviceUDID,
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
                          @"-d", defaultDeviceUDID
                          ];
        
        if ([CLI process:args] == iOSReturnStatusCodeFalse) {
            args = @[
                     kProgramName, @"install",
                     @"-a", testApp(ARM),
                     @"-d", defaultDeviceUDID
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }
        
        args = @[
                 kProgramName, @"launch_app",
                 @"-b", testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        
        args = @[
                 kProgramName, @"kill_app",
                 @"-b", testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

@end
