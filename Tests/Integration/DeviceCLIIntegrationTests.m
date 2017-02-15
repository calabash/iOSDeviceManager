
#import "DeviceCLIIntegrationTests.h"

@interface DeviceCLIIntegrationTests()

@end

@implementation DeviceCLIIntegrationTests

- (void)setUp {
    [[Resources shared] setDeveloperDirectory];
    [Simctl shared];
    
    XCTAssertNotNil(self.platform, @"Must set a platform");
    XCTAssertNotNil(self.codesignID, @"Must set a codesigning identity");
    XCTAssertNotNil(self.deviceID, @"Must set a device identifier1");
    
    [super setUp];
}

- (Resources *)resources {
    return [Resources shared];
}

- (NSString *)appBundleVersion:(NSString *)bundleID {
    NSDictionary *plist;
    plist = [[Device withID:self.deviceID] installedApp:bundleID].infoPlist;
    return plist[@"CFBundleVersion"];
}

- (BOOL)isInstalled:(NSString *)bundleID {
    NSArray *args = @[
                      kProgramName, @"is_installed",
                      @"-b", bundleID,
                      @"-d", self.deviceID
                      ];
    iOSReturnStatusCode installedRC = [CLI process:args];
    
    XCTAssertTrue(installedRC == iOSReturnStatusCodeFalse ||
                  installedRC == iOSReturnStatusCodeEverythingOkay,
                  @"Error checking if %@ is installed on %@", bundleID, self.deviceID);
    return installedRC == iOSReturnStatusCodeFalse ? NO : YES;
}

- (void)uninstallOrThrow:(NSString *)bundleID {
    if ([self isInstalled:bundleID]) {
        NSArray *args = @[
                 kProgramName, @"uninstall",
                 @"-d", self.deviceID,
                 @"-b", bundleID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    XCTAssertFalse([self isInstalled:bundleID]);
}

- (void)installOrThrow:(NSString *)appPath bundleID:(NSString *)bundleID shouldUpdate:(BOOL)shouldUpdate {
    if (shouldUpdate) {
        NSArray *args = @[kProgramName, @"install",
                          @"-d", self.deviceID,
                          @"-c", self.codesignID,
                          @"-a", appPath,
                          @"-u", @"YES"];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    } else {
        if (![self isInstalled:bundleID]) {
            NSArray *args = @[kProgramName, @"install",
                              @"-d", self.deviceID,
                              @"-c", self.codesignID,
                              @"-a", appPath];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }
    }
    
    XCTAssertTrue([self isInstalled:bundleID]);
}

- (iOSReturnStatusCode)startTest {
    NSArray *args = @[kProgramName, @"start_test",
                      @"-d", self.deviceID,
                      @"-k", @"NO"];
    return [CLI process:args];
}

- (iOSReturnStatusCode)setLocation:(NSString *)location {
    NSArray *args = @[kProgramName, @"set_location", @"-d", self.deviceID, @"-l", location];
    return [CLI process:args];
}

#pragma mark - Shared Tests
- (void)sharedInstallTest {
    //Ensure app isn't installed
    [self uninstallOrThrow:taskyAppID];
    
    //Test absolute path install
    [self installOrThrow:tasky(self.platform) bundleID:taskyAppID shouldUpdate:NO];
    [self uninstallOrThrow:testAppID];
    
    //Test relative path install
    [self installOrThrow:[self.resources TestAppRelativePath:self.platform]
                bundleID:testAppID shouldUpdate:NO];
}

- (void)sharedUninstallTest {
    //Ensure app isn't installed
    [self uninstallOrThrow:testAppID];
    
    //Install it
    [self installOrThrow:[self.resources TestAppPath:self.platform] bundleID:testAppID shouldUpdate:NO];
    
    //Ensure it can be uninstalled
    [self uninstallOrThrow:testAppID];
}

- (void)sharedAppIsInstalledTest {
    //Sanity check: settings app should always be installed
    XCTAssertTrue([self isInstalled:@"com.apple.Preferences"]);
    
    [self uninstallOrThrow:testAppID];
    XCTAssertFalse([self isInstalled:testAppID]); //redundant but just for clarity
    
    [self installOrThrow:testApp(self.platform) bundleID:testAppID shouldUpdate:NO];
    XCTAssertTrue([self isInstalled:testAppID]); //also redundant, also for clarity
}

- (void)sharedUploadFileTest {
    [self uninstallOrThrow:testAppID];
    [self installOrThrow:testApp(self.platform) bundleID:testAppID shouldUpdate:NO];
    
    //Upload a unique file
    NSString *file = uniqueFile();
    NSArray *args = @[
                      kProgramName, @"upload",
                      @"-b", testAppID,
                      @"-d", defaultSimUDID,
                      @"-f", file,
                      @"-o", @"NO"
                      ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    //Now attempt to overwrite with -o false
    args = @[
             kProgramName, @"upload",
             @"-b", testAppID,
             @"-d", defaultSimUDID,
             @"-f", file,
             @"-o", @"NO"
             ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);
    
    //Now attempt to overwrite with -o true
    args = @[
             kProgramName, @"upload",
             @"-b", testAppID,
             @"-d", defaultSimUDID,
             @"-f", file,
             @"-o", @"YES"
             ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)sharedAppUpdateTest {
    //Ensure app is not installed
    [self uninstallOrThrow:testAppID];
    
    //Set app's info.plist CFBundleVersion to 1.0
    NSString *tmpDir = [self.resources uniqueTmpDirectory];
    NSString *source = testApp(self.platform);
    NSString *target = [tmpDir stringByAppendingPathComponent:[source lastPathComponent]];
    [self.resources copyDirectoryWithSource:source target:target];
    
    XCTAssertTrue([self.resources updatePlistForBundle:target
                                                   key:@"CFBundleVersion"
                                                 value:@"1.0"]);
    
    [self installOrThrow:target bundleID:testAppID shouldUpdate:NO];
    
    //Ensure that the installed app has CFBundleVersion 1.0
    NSString *installedVersion = [self appBundleVersion:testAppID];
    XCTAssertEqualObjects(installedVersion, @"1.0",
                          @"Installed app's Info.plist doesn't match");
    
    //Now update the local plist to have CFBundleVersion 2.0
    XCTAssertTrue([self.resources updatePlistForBundle:target
                                                   key:@"CFBundleVersion"
                                                 value:@"2.0"]);
    
    //Install the app and ensure that the new version has been installed
    [self installOrThrow:target bundleID:testAppID shouldUpdate:YES];
    
    installedVersion = [self appBundleVersion:testAppID];
    XCTAssertEqualObjects(installedVersion, @"2.0",
                          @"Installed app's Info.plist doesn't match");
    
    
    //Now change it back to 1.0 and try to install while setting `-u` to false.
    //We should see that the installed version remains at 2.0
    XCTAssertTrue([self.resources updatePlistForBundle:target
                                                   key:@"CFBundleVersion"
                                                 value:@"1.0"]);
    
    [self installOrThrow:target bundleID:testAppID shouldUpdate:NO];
    
    installedVersion = [self appBundleVersion:testAppID];
    XCTAssertEqualObjects(installedVersion, @"2.0",
                          @"App was updated even though -u was set to NO");
}

- (void)sharedLaunchAndKillAppTest {
    [self installOrThrow:testApp(self.platform) bundleID:testAppID shouldUpdate:NO];
    
    NSArray *args = @[kProgramName, @"launch_app", self.deviceID, @"-b", testAppID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    //TODO: Verify app is running
    
    args = @[kProgramName, @"kill_app", self.deviceID, @"-b", testAppID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)sharedSetLocationTest {
    //Should fail: invalid coordinates
    XCTAssertEqual([self setLocation:@"banana"], iOSReturnStatusCodeInvalidArguments);
    
    //Should pass: Stockholm coordinates point to a real place.
    XCTAssertEqual([self setLocation:kStockholmCoord], iOSReturnStatusCodeEverythingOkay);
}

- (void)sharedOptionalArgsTest {
    //Start from clean slate
    [self uninstallOrThrow:testAppID];
    NSString *relativeAppPath = [self.resources TestAppRelativePath:self.platform];
    NSArray *args;
    
    /*
        $ idm install relative/path/to/app
     */
    args = @[kProgramName, @"install", relativeAppPath];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    [self uninstallOrThrow:testAppID];
    
    /*
        $ idm install absolute/path/to/app
     */
    args = @[kProgramName, @"install", testApp(self.platform)];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    [self uninstallOrThrow:testAppID];
    
    /*
        $ idm start_test <device_id> <test_runner_bundle_id>
     */
    [self installOrThrow:runner(self.platform) bundleID:kDeviceAgentBundleID shouldUpdate:NO];
    args = @[kProgramName, @"start_test", self.deviceID, kDeviceAgentBundleID, @"-k", @"NO"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    /*
     $ idm start_test <device_id>
     */
    args = @[kProgramName, @"start_test", self.deviceID, @"-k", @"NO"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    /*
     $ idm start_test <test_runner_bundle_id>
     */
    args = @[kProgramName, @"start_test", kDeviceAgentBundleID, @"-k", @"NO"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    /*
     $ idm start_test
     */
    args = @[kProgramName, @"start_test", @"-k", @"NO"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)sharedStopSimulatingLocationTest {
    NSArray *args = @[
                      kProgramName, @"stop_simulating_location",
                      @"-d", self.deviceID
                      ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)sharedPositionalArgsTest {
    //Start from a clean slate.
    [self uninstallOrThrow:testAppID];
    NSString *relativeAppPath = [self.resources TestAppRelativePath:self.platform];
    NSArray *args;
    
    /*
        $idm install absolute/path/to/app device_id
     */
    args = @[kProgramName, @"install", testApp(self.platform), self.deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    [self uninstallOrThrow:testAppID];
    
    /*
        $idm install device_id absolute/path/to/app
     */
    args = @[kProgramName, @"install", self.deviceID, testApp(self.platform)];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    [self uninstallOrThrow:testAppID];
    
    /*
     $idm install relative/path/to/app device_id
     */
    args = @[kProgramName, @"install", relativeAppPath, self.deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    [self uninstallOrThrow:testAppID];
    
    /*
        $ idm install device_id relative/path/to/app
     */
    args = @[kProgramName, @"install", self.deviceID, relativeAppPath];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    [self uninstallOrThrow:testAppID];
    

    /*
        $ idm install <app_path> => missing args
     */
    args = @[kProgramName, @"install", self.deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
    [self uninstallOrThrow:testAppID];
    
    /*
         $ idm install <non_existant_app_path> => missing args
     */
    args = @[kProgramName, @"install", self.deviceID, testApp(self.platform), @"-a", @"/path/to/another/app"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInvalidArguments);
    [self uninstallOrThrow:testAppID];
    
    /* 
        $ idm install <device_id> <app_path> -d <another_device_id> => invalid args
     */
    args = @[kProgramName, @"install", self.deviceID, testApp(self.platform), @"-d", self.deviceID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInvalidArguments);
    [self uninstallOrThrow:testAppID];
}

@end
