
#import "TestCase.h"
#import "CLI.h"
#import "DeviceUtils.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "PhysicalDevice.h"

@interface PhysicalDevice (TEST)

- (FBDevice *)fbDevice;

@end

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
                 @"-i", [[Resources shared] CalabashDylibPath]
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

- (void)testResignObject {
    ShellResult *result;
    CodesignIdentity *identity = [self.resources JoshuaMoodyIdentityIOS];

    NSString *target = [[self.resources uniqueTmpDirectory] stringByAppendingPathComponent:@"signed.dylib"];
    NSString *source = [self.resources CalabashDylibPath];
    NSFileManager *manager = [NSFileManager defaultManager];
    expect([manager copyItemAtPath:source toPath:target error:nil]).to.beTruthy();

    NSArray *args = @[
                      kProgramName, @"resign-object",
                      target,
                      [identity shasum]
                      ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    result = [ShellRunner xcrun:@[@"codesign", @"--display", target] timeout:5];
    expect([[result stdoutStr] containsString:identity.name]);
}

- (void)testInstallAndInjectTestRecorder {

    if (!device_available()) { return; }

    // --update-app flag is not working, so we must uninstall.
    // When injecting resources, we should _always_ reinstall because
    // the version of the resources may have changed?
    Application *app = [Application withBundlePath:testApp(ARM)];
    PhysicalDevice *device = [PhysicalDevice withID:defaultDeviceUDID];

    if ([device isInstalled:app.bundleID withError:nil]) {
        expect(
               [device uninstallApp:app.bundleID]
               ).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    NSString *dylibPath = [[Resources shared] TestRecorderDylibPath];
    NSArray *args = @[kProgramName,
                      @"install",
                      app.path,
                      @"--device-id", device.uuid,
                      @"--resources-path", dylibPath
                      ];

    expect([CLI process:args]).to.equal(iOSReturnStatusCodeEverythingOkay);

    expect(
           [device launchApp:[app bundleID]]
           ).to.equal(iOSReturnStatusCodeEverythingOkay);

    __block NSString *version = nil;

    // This can be improved upon
    // https://github.com/calabash/run_loop/blob/develop/lib/run_loop/device_agent/client.rb#L1128
    NSString *hostname = [NSString stringWithFormat:@"%@.local",
                          device.fbDevice.name];

    [[[FBRunLoopSpinner new] timeout:30] spinUntilTrue:^BOOL{
        version = [[Resources shared] TestRecorderVersionFromHost:hostname];
        return version != nil;
    }];

    expect(version).to.beTruthy();
}

@end
