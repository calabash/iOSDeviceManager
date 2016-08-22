
#import "TestCase.h"
#import "CLI.h"

@interface PhysicalDeviceCLIIntegrationTests : TestCase

@end

@implementation PhysicalDeviceCLIIntegrationTests

- (void)setUp {
    [super setUp];
}

// This is a blocking test.
//
// It cannot be automated yet because CLI process: blocks the main thread _and_ it must
// be run on the main thread.
//
//- (void)testStartTest {
//    if (device_available()) {
//        NSArray *args = @[
//                kProgramName, @"start_test",
//                @"-d", defaultDeviceUDID,
//                @"-t", xctest(ARM),
//                @"-r", runner(ARM),
//                @"-c", kCodeSignIdentityKARL,
//                @"-u", @"YES",
//                @"-k", @"YES"
//        ];
//
//        [CLI process:args];
//    } else {
//        NSLog(@"No compatible device connected; skipping test");
//    }
//}

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
    } else {
        NSLog(@"No compatible device connected; skipping test");
    }
}

- (void)testStopSimulatingLocation {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"stop_simulating_location",
                          @"-d", defaultDeviceUDID
                          ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    } else {
        NSLog(@"No compatible device connected; skipping test");
    }
}

- (void)testUninstall {
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"is_installed",
                          @"-b", testApp(ARM),
                          @"-d", testAppID
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
    } else {
        NSLog(@"No compatible device connected; skipping test");
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
    } else {
        NSLog(@"No compatible device connected; skipping test");
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
    } else {
        NSLog(@"No compatible device connected; skipping test");
    }
}

@end
