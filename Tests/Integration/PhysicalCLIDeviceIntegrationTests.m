
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
                          kProgramName, @"set-location",
                          @"Banana",
                          @"-d", defaultDeviceUDID
                          ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInvalidArguments);

        args = @[
                 kProgramName, @"set-location",
                 kStockholmCoord,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testStopSimulatingLocation {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"stop-simulating-location",
                          @"-d", defaultDeviceUDID
                          ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testUninstall {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"is-installed",
                          testAppID,
                          @"-d", defaultDeviceUDID
                          ];
        if ([CLI process:args] == iOSReturnStatusCodeFalse) {
            args = @[kProgramName, @"install",
                     testApp(ARM),
                     @"-d", defaultDeviceUDID,
                     @"-c", kCodeSignIdentityKARL];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }

        args = @[
                 kProgramName, @"uninstall",
                 testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        args = @[
                 kProgramName, @"is-installed",
                 testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeFalse);
    }
}

- (void)testInstall {
    if (device_available()) {
            NSArray *args = @[
                              kProgramName, @"is-installed",
                              testAppID,
                              @"-d", defaultDeviceUDID
                              ];
            
            if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
                args = @[
                         kProgramName, @"uninstall",
                         testAppID,
                         @"-d", defaultDeviceUDID
                         ];
                XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
            }
            
            args = @[
                     kProgramName, @"install",
                     testApp(ARM),
                     @"-d", defaultDeviceUDID,
                     @"-c", kCodeSignIdentityKARL
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        // Test installing with injecting resource
        args = @[
                  kProgramName, @"is-installed",
                  testAppID,
                  @"-d", defaultDeviceUDID
                ];

        if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
            args = @[
                     kProgramName, @"uninstall",
                     testAppID,
                     @"-d", defaultDeviceUDID
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }

        args = @[
                 kProgramName, @"install",
                 testApp(ARM),
                 @"-d", defaultDeviceUDID,
                 @"-c", kCodeSignIdentityKARL,
                 @"-i", [CodesignResources CalabashDylibPath]
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        args = @[
                 kProgramName, @"launch-app",
                 testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        [NSThread sleepForTimeInterval:5];

        NSError *error;
        pid_t pid = [[[Device withID:defaultDeviceUDID] fbDeviceOperator] processIDWithBundleID:testAppID error:&error];
        XCTAssertTrue(pid > 0);
    }
}

- (void)testAppInfo {
    if (device_available()) {
        NSArray *args = args = @[
                 kProgramName, @"is-installed",
                 testAppID,
                 @"-d", defaultDeviceUDID
                 ];

        if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
            args = @[
                     kProgramName, @"uninstall",
                     testAppID,
                     @"-d", defaultDeviceUDID,
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }

        args = @[
                 kProgramName, @"is-installed",
                 testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeFalse);

        args = @[
                 kProgramName, @"install",
                 testApp(ARM),
                 @"-d", defaultDeviceUDID,
                 @"-c", kCodeSignIdentityKARL
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        args = @[kProgramName, @"app-info", testAppID, @"-d", defaultDeviceUDID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testAppIsInstalled {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"is-installed",
                          @"com.apple.Preferences",
                          @"-d", defaultDeviceUDID
                          ];

        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        args = @[
                 kProgramName, @"is-installed",
                 testAppID,
                 @"-d", defaultDeviceUDID
                 ];

        if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
            args = @[
                     kProgramName, @"uninstall",
                     testAppID,
                     @"-d", defaultDeviceUDID,
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }

        args = @[
                 kProgramName, @"is-installed",
                 testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeFalse);

        args = @[
                 kProgramName, @"install",
                 testApp(ARM),
                 @"-d", defaultDeviceUDID,
                 @"-c", kCodeSignIdentityKARL
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        args = @[
                 kProgramName, @"is-installed",
                 testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testUploadFile {
    if (device_available()) {
        //Ensure app installed
        NSArray *args = @[
                          kProgramName, @"is-installed",
                          testAppID,
                          @"-d", defaultDeviceUDID
                          ];
        
        if ([CLI process:args] == iOSReturnStatusCodeFalse) {
            args = @[
                     kProgramName, @"install",
                     testApp(ARM),
                     @"-d", defaultDeviceUDID,
                     @"-c", kCodeSignIdentityKARL
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }
        
        //Upload a unique file
        NSString *file = uniqueFile();
        args = @[
                 kProgramName, @"upload",
                 file,
                 testAppID,
                 @"-d", defaultDeviceUDID,
                 @"-o", @"NO"
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        
        //Now attempt to overwrite with -o false
        args = @[
                 kProgramName, @"upload",
                 file,
                 testAppID,
                 @"-d", defaultDeviceUDID,
                 @"-o", @"NO"
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);
        
        //Now attempt to overwrite with -o true
        args = @[
                 kProgramName, @"upload",
                 file,
                 testAppID,
                 @"-d", defaultDeviceUDID,
                 @"-o", @"YES"
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testLaunchAndKillApp {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"is-installed",
                          testAppID,
                          @"-d", defaultDeviceUDID
                          ];
        
        if ([CLI process:args] == iOSReturnStatusCodeFalse) {
            args = @[
                     kProgramName, @"install",
                     testApp(ARM),
                     @"-d", defaultDeviceUDID
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }
        
        args = @[
                 kProgramName, @"launch-app",
                 testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        
        args = @[
                 kProgramName, @"kill-app",
                 testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

@end
