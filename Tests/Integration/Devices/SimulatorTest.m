
#import "TestCase.h"
#import "Device.h"
#import "Simulator.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "Application.h"
#import "XCAppDataBundle.h"
#import "CLI.h"

@interface Simulator (TEST)

- (BOOL)boot;
- (FBSimulator *)fbSimulator;
- (BOOL)waitForBootableState:(NSError *__autoreleasing *)error;
+ (FBSimulatorLifecycleCommands *)lifecycleCommandsWithFBSimulator:(FBSimulator *)fbSimulator;

@end

@interface SimulatorTest : TestCase

@property (atomic, strong) Simulator *simulator;

@end

@implementation SimulatorTest

- (void)setUp {
    [super setUp];
    [Simulator killSimulatorApp];
    self.simulator = [Simulator withID:defaultSimUDID];
}

- (void)tearDown {
    self.simulator = nil;
    [super tearDown];
}

- (void)testLaunchSimulator {
    iOSReturnStatusCode code = [Simulator launchSimulator:self.simulator];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
}

// Ignore test because it breaks CI execution
- (void)ignore_testLaunchSimulatorRestartsIfSimulatorIsNotCorrect {
    iOSReturnStatusCode code = [Simulator launchSimulator:self.simulator];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    NSArray<TestSimulator *> *simulators = [[Resources shared] simulators];
    NSUInteger index = arc4random() % [simulators count];
    TestSimulator *testSim = simulators[index];
    Simulator *other = [Simulator withID:testSim.UDID];

    code = [Simulator launchSimulator:other];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
}

- (void)testBoot {
    expect([self.simulator boot]).to.equal(YES);

    // Safe to call in state Booted
    expect([self.simulator boot]).to.equal(YES);
}

- (void)testInstallPathAndContainerPathForApplication {
    expect([self.simulator boot]).to.beTruthy();

    Application *app = [Application withBundlePath:testApp(SIM)];
    iOSReturnStatusCode code = [self.simulator installApp:app forceReinstall:NO];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
    NSString *bundleIdentifier = @"sh.calaba.TestApp";
    NSString *installPath = [self.simulator installPathForApplication:bundleIdentifier];
    NSString *containerPath = [self.simulator containerPathForApplication:bundleIdentifier];

    expect(installPath).notTo.beNil;
    expect([installPath containsString:self.simulator.uuid]).to.beTruthy;
    expect([installPath containsString:@"data/Containers/Bundle/Application"]).to.beTruthy;
    expect([installPath containsString:@"TestApp.app"]).to.beTruthy;

    expect(containerPath).notTo.beNil;
    expect([containerPath containsString:self.simulator.uuid]).to.beTruthy;
    expect([containerPath containsString:@"data/Containers/Data/Application"]).to.beTruthy;

    NSString *plistName = @".com.apple.mobile_container_manager.metadata.plist";
    NSString *plistPath = [containerPath stringByAppendingPathComponent:plistName];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    expect(dictionary[@"MCMMetadataIdentifier"]).to.equal(bundleIdentifier);

    bundleIdentifier = @"com.example.NoSuchApp";
    installPath = [self.simulator installPathForApplication:bundleIdentifier];
    containerPath = [self.simulator containerPathForApplication:bundleIdentifier];

    expect(installPath).to.beNil;
    expect(containerPath).to.beNil;
}

- (void)testInstallAndInjectTestRecorder {
    expect([self.simulator boot]).to.beTruthy();

    NSArray *resources = @[[[Resources shared] TestRecorderDylibPath]];

    // shouldUpdate argument is broken, so we need to uninstall
    // When injecting resources, we should _always_ reinstall because
    // the version of the resources may have changed?
    Application *app = [Application withBundlePath:testApp(SIM)];

    if ([self.simulator isInstalled:app.bundleID withError:nil]) {
        expect(
               [self.simulator uninstallApp:app.bundleID]
               ).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    iOSReturnStatusCode code = [self.simulator installApp:app
                                        resourcesToInject:resources
                                             forceReinstall:NO];

    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    code = [self.simulator launchApp:[app bundleID]];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    __block NSString *version = nil;

    [[[FBRunLoopSpinner new] timeout:180] spinUntilTrue:^BOOL{
        version = [[Resources shared] TestRecorderVersionFromHost:@"127.0.0.1"];
        return version != nil;
    }];

    expect(version).to.beTruthy();
}

- (void)testUploadXCAppDataBundleCLI {
    expect([self.simulator boot]).to.beTruthy();

    iOSReturnStatusCode code;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    Application *app = [Application withBundlePath:testApp(SIM)];

    if (![self.simulator isInstalled:app.bundleID withError:nil]) {
        code = [self.simulator installApp:app resourcesToInject:nil forceReinstall:NO];
        expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    NSString *path = [[Resources shared] uniqueTmpDirectory];
    NSString *xcappdata = [path stringByAppendingPathComponent:@"New.xcappdata"];
    expect([XCAppDataBundle generateBundleSkeleton:path
                                              name:@"New.xcappdata"
                                         overwrite:YES]).to.beTruthy();
    NSArray *sources = [XCAppDataBundle sourceDirectoriesForSimulator:xcappdata];
    for (NSString *source in sources) {
        NSString *file = [source stringByAppendingPathComponent:@"file.txt"];
        NSData *data = [@"contents" dataUsingEncoding:NSUTF8StringEncoding];
        expect([fileManager createFileAtPath:file
                                    contents:data
                                  attributes:nil]).to.beTruthy();
    }

    // works with bundle identifier
    NSArray *args = @[kProgramName, @"upload-xcappdata",
                      app.bundleID, xcappdata,
                      @"--device-id", self.simulator.uuid];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    // works with app path
    args = @[kProgramName, @"upload-xcappdata",
             app.path, xcappdata,
             @"--device-id", self.simulator.uuid];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testUploadXCAppDataBundle {
    expect([self.simulator boot]).to.beTruthy();

    iOSReturnStatusCode code;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    Application *app = [Application withBundlePath:testApp(SIM)];

    if (![self.simulator isInstalled:app.bundleID withError:nil]) {
        code = [self.simulator installApp:app resourcesToInject:nil forceReinstall:NO];
        expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    // invalid xcappdata bundle
    NSString *path = [[Resources shared] uniqueTmpDirectory];
    code = [self.simulator uploadXCAppDataBundle:path forApplication:app.bundleID];
    expect(code).to.equal(iOSReturnStatusCodeGenericFailure);

    // installs successfully
    NSString *xcappdata = [path stringByAppendingPathComponent:@"New.xcappdata"];
    expect([XCAppDataBundle generateBundleSkeleton:path
                                              name:@"New.xcappdata"
                                         overwrite:YES]).to.beTruthy();
    NSArray *sources = [XCAppDataBundle sourceDirectoriesForSimulator:xcappdata];
    for (NSString *source in sources) {
        NSString *file = [source stringByAppendingPathComponent:@"file.txt"];
        NSData *data = [@"contents" dataUsingEncoding:NSUTF8StringEncoding];
        expect([fileManager createFileAtPath:file
                                    contents:data
                                  attributes:nil]).to.beTruthy();
    }
    code = [self.simulator uploadXCAppDataBundle:xcappdata forApplication:app.bundleID];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    NSString *containerPath = [self.simulator containerPathForApplication:app.bundleID];
    NSArray *targets = @[
                         [containerPath stringByAppendingPathComponent:@"Documents"],
                         [containerPath stringByAppendingPathComponent:@"Library"],
                         [containerPath stringByAppendingPathComponent:@"tmp"]
                         ];

    for (NSString *target in targets) {
        NSString *file = [target stringByAppendingPathComponent:@"file.txt"];
        expect([fileManager fileExistsAtPath:file isDirectory:nil]).to.beTruthy();
    }

    // fails if application is not installed
    code = [self.simulator uninstallApp:app.bundleID];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
    code = [self.simulator uploadXCAppDataBundle:xcappdata forApplication:app.bundleID];
    expect(code).to.equal(iOSReturnStatusCodeGenericFailure);
}

@end
