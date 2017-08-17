
#import "TestCase.h"
#import "PhysicalDevice.h"
#import "Application.h"
#import "XCAppDataBundle.h"
#import "CLI.h"

@interface PhysicalDevice (TEST)

- (FBDevice *)fbDevice;

@end

@interface PhysicalDeviceTest : TestCase

@end

@implementation PhysicalDeviceTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInstallAndUninstall {
    if (!device_available()) { return; }

    PhysicalDevice *device = [PhysicalDevice withID:defaultDeviceUDID];
    Application *app = [Application withBundlePath:testApp(ARM)];
    NSError *error = nil;
    BOOL installed = NO;
    iOSReturnStatusCode code = iOSReturnStatusCodeGenericFailure;

    if ([device isInstalled:[app bundleID] withError:&error]) {
        code = [device uninstallApp:[app bundleID]];
        expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
        BOOL installed = [device isInstalled:[app bundleID] withError:&error];
        expect(installed).to.equal(NO);
    }

    code = [device installApp:app shouldUpdate:YES];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
    installed = [device isInstalled:[app bundleID] withError:&error];
    expect(installed).to.equal(YES);

    code = [device uninstallApp:[app bundleID]];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
    installed = [device isInstalled:[app bundleID] withError:&error];
    expect(installed).to.equal(NO);
}

- (void)testInstallPathAndContainerPathForApplication {
    if (!device_available()) { return; }

    PhysicalDevice *device = [PhysicalDevice withID:defaultDeviceUDID];

    Application *app = [Application withBundlePath:testApp(ARM)];
    [device installApp:app shouldUpdate:YES];

    NSString *bundleIdentifier = @"sh.calaba.TestApp";
    NSString *installPath = [device installPathForApplication:bundleIdentifier];
    NSString *containerPath = [device containerPathForApplication:bundleIdentifier];
    NSLog(@"  install: %@", installPath);
    NSLog(@"container: %@", containerPath);

    expect(installPath).notTo.beNil;
    expect([installPath containsString:@"data/Containers/Bundle/Application"]).to.beTruthy;
    expect([installPath containsString:@"TestApp.app"]).to.beTruthy;

    expect(containerPath).notTo.beNil;
    expect([containerPath containsString:@"data/Containers/Data/Application"]).to.beTruthy;

    bundleIdentifier = @"com.example.NoSuchApp";
    installPath = [device installPathForApplication:bundleIdentifier];
    containerPath = [device containerPathForApplication:bundleIdentifier];

    expect(installPath).to.beNil;
    expect(containerPath).to.beNil;
}

- (void)testInstallAndInjectTestRecorder {
    if (!device_available()) { return; }

    // shouldUpdate argument is broken, so we need to uninstall
    // When injecting resources, we should _always_ reinstall because
    // the version of the resources may have changed?
    PhysicalDevice *device = [PhysicalDevice withID:defaultDeviceUDID];

    NSArray *resources = @[[[Resources shared] TestRecorderDylibPath]];
    Application *app = [Application withBundlePath:testApp(ARM)];

    if ([device isInstalled:app.bundleID withError:nil]) {
        expect(
               [device uninstallApp:app.bundleID]
               ).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    iOSReturnStatusCode code = [device installApp:app
                                resourcesToInject:resources
                                     shouldUpdate:NO];

    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    code = [device launchApp:[app bundleID]];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

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

- (void)testUploadXCAppDataBundle {
    if (!device_available()) { return; }

    iOSReturnStatusCode code;

    PhysicalDevice *device = [PhysicalDevice withID:defaultDeviceUDID];

    Application *app = [Application withBundlePath:testApp(ARM)];
    code = [device installApp:app shouldUpdate:YES];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    // invalid xcappdata bundle
    NSString *path = [[Resources shared] uniqueTmpDirectory];
    code = [device uploadXCAppDataBundle:path forApplication:app.bundleID];
    expect(code).to.equal(iOSReturnStatusCodeGenericFailure);

    // installs successfully
    NSString *xcappdata = [path stringByAppendingPathComponent:@"New.xcappdata"];
    expect([XCAppDataBundle generateBundleSkeleton:path
                                              name:@"New.xcappdata"
                                         overwrite:YES]).to.beTruthy();

    code = [device uploadXCAppDataBundle:xcappdata forApplication:app.bundleID];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    // fails if application is not installed
    code = [device uninstallApp:app.bundleID];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
    code = [device uploadXCAppDataBundle:xcappdata forApplication:app.bundleID];
    expect(code).to.equal(iOSReturnStatusCodeInternalError);
}

- (void)testUploadXCAppDataBundleCLI {
    if (!device_available()) { return; }

    iOSReturnStatusCode code;

    PhysicalDevice *device = [PhysicalDevice withID:defaultDeviceUDID];

    Application *app = [Application withBundlePath:testApp(ARM)];
    code = [device installApp:app shouldUpdate:YES];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    NSString *path = [[Resources shared] uniqueTmpDirectory];
    NSString *xcappdata = [path stringByAppendingPathComponent:@"New.xcappdata"];
    expect([XCAppDataBundle generateBundleSkeleton:path
                                              name:@"New.xcappdata"
                                         overwrite:YES]).to.beTruthy();


    // works with bundle identifier
    NSArray *args = @[kProgramName, @"upload-xcappdata",
                      app.bundleID, xcappdata,
                      @"--device-id", device.uuid];
    code = [CLI process:args];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    // works with path/to/app
    args = @[kProgramName, @"upload-xcappdata",
             testApp(ARM), xcappdata,
             @"--device-id", device.uuid];
    code = [CLI process:args];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
}

- (void)testUploadXCTestConfigurationCLI {
    if (!device_available()) { return; }

    iOSReturnStatusCode code;

    PhysicalDevice *device = [PhysicalDevice withID:defaultDeviceUDID];

    NSString *path = [[Resources shared] DeviceAgentPath:@"ARM"];
    Application *app = [Application withBundlePath:path];
    code = [device installApp:app shouldUpdate:YES];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    // works with bundle identifier
    NSArray *args = @[kProgramName, @"upload-xctestconf",
                      app.bundleID, @"--device-id", device.uuid];
    code = [CLI process:args];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    // works with path/to/app
    args = @[kProgramName, @"upload-xctestconf",
             app.path, @"--device-id", device.uuid];
    code = [CLI process:args];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
}

@end
