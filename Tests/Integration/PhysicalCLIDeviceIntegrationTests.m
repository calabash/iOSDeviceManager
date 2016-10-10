
#import "TestCase.h"
#import "CLI.h"

@interface PhysicalDeviceCLIIntegrationTests : TestCase

@end

@implementation PhysicalDeviceCLIIntegrationTests

- (void)setUp {
    [super setUp];
}

//  Hangs indefinitely.
/*
- (void)testStartTest {
    if (device_available()) {
        NSArray *args = @[
                @"start_test",
                @"-d", defaultDeviceUDID,
                @"-s", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
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
                          @"set_location",
                          @"-d", defaultDeviceUDID,
                          @"-l", @"Banana"
                          ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInvalidArguments);

        args = @[
                 @"set_location",
                 @"-d", defaultDeviceUDID, @"-l",
                 kStockholmCoord
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testStopSimulatingLocation {
    if (device_available()) {
        NSArray *args = @[
                          @"stop_simulating_location",
                          @"-d", defaultDeviceUDID
                          ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testUninstall {
    if (device_available()) {
        NSArray *args = @[
                          @"is_installed",
                          @"-b", testApp(ARM),
                          @"-d", testAppID
                          ];
        if ([CLI process:args] == iOSReturnStatusCodeFalse) {
            args = @[@"install",
                     @"-d", defaultDeviceUDID,
                     @"-a", testApp(ARM),
                     @"-c", kCodeSignIdentityKARL];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }

        args = @[
                 @"uninstall",
                 @"-d", defaultDeviceUDID,
                 @"-b", testAppID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testInstall {
    if (device_available()) {
            NSArray *args = @[
                              @"is_installed",
                              @"-b", testAppID,
                              @"-d", defaultDeviceUDID
                              ];
            
            if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
                args = @[
                         @"uninstall",
                         @"-d", defaultDeviceUDID,
                         @"-b", testAppID
                         ];
                XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
            }
            
            args = @[
                     @"install",
                     @"-d", defaultDeviceUDID,
                     @"-a", testApp(ARM),
                     @"-c", kCodeSignIdentityKARL
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testAppIsInstalled {
    if (device_available()) {
        NSArray *args = @[
                          @"is_installed",
                          @"-b", @"com.apple.Preferences",
                          @"-d", defaultDeviceUDID
                          ];

        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        args = @[
                 @"is_installed",
                 @"-b", testAppID,
                 @"-d", defaultDeviceUDID
                 ];

        if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
            args = @[
                     @"uninstall",
                     @"-d", defaultDeviceUDID,
                     @"-b", testAppID
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }

        args = @[
                 @"is_installed",
                 @"-b", testAppID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeFalse);

        args = @[
                 @"install",
                 @"-d", defaultDeviceUDID,
                 @"-a", testApp(ARM),
                 @"-c", kCodeSignIdentityKARL
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

        args = @[
                 @"is_installed",
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

@end
