
#import "TestCase.h"
#import "Device.h"
#import "Simulator.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "Application.h"
#import "XCAppDataBundle.h"
#import "CLI.h"

@interface Simulator (TEST)

- (FBSimulator *)fbSimulator;
- (BOOL)bootIfNecessary:(NSError * __autoreleasing *) error;
- (BOOL)waitForBootableState:(NSError *__autoreleasing *)error;
+ (FBSimulatorLifecycleCommands *)lifecycleCommandsWithFBSimulator:(FBSimulator *)fbSimulator;

@end

@interface SimulatorTest : TestCase

@property (atomic, strong) Simulator *simulator;

@end

@implementation SimulatorTest

- (void)setUp {
    [super setUp];
    [self quitSimulators];
    self.simulator = [Simulator withID:defaultSimUDID];
}

- (void)tearDown {
    [self.simulator kill];
    self.simulator = nil;
    [super tearDown];
}

- (void)quitSimulatorsWithSignal:(NSString *)signal {
    NSArray<NSString *> *args =
    @[
      @"pkill",
      [NSString stringWithFormat:@"-%@", signal],
      @"Simulator"
      ];

    ShellResult *result = [ShellRunner xcrun:args timeout:10];

    XCTAssertTrue([result success],
                  @"Failed to send %@ signal to Simulator.app", signal);

    __block NSArray<TestSimulator *> *simulators = [[Resources shared] simulators];
    [[[FBRunLoopSpinner new] timeout:30] spinUntilTrue:^BOOL{

        NSMutableArray *mutable = [NSMutableArray arrayWithCapacity:100];
        for (TestSimulator *simulator in simulators) {
            if (![[simulator stateString] isEqualToString:@"Shutdown"]) {
                [ShellRunner xcrun:@[@"simctl", @"shutdown", simulator.UDID]
                           timeout:10];
                [mutable addObject:simulator];
            }
        }
        simulators = [NSArray arrayWithArray:mutable];
        return [simulators count] == 0;
    }];
}

- (void)quitSimulators {
    [self quitSimulatorsWithSignal:@"TERM"];
    [self quitSimulatorsWithSignal:@"KILL"];
}

- (void)testBootSimulatorIfNecessarySuccess {
    NSError *error = nil;
    BOOL success = NO;

    // Boot required
    success = [self.simulator bootIfNecessary:&error];
    XCTAssertTrue(success,
                  @"Boot is necessary - failed with error: %@",
                  error);
    expect(error).to.beNil;

    [[[FBRunLoopSpinner new] timeout:30] spinUntilTrue:^BOOL{
        return self.simulator.fbSimulator.state == FBSimulatorStateBooted;
    }];

    // Boot not required
    success = [self.simulator bootIfNecessary:&error];
    XCTAssertTrue(success,
                  @"Boot is unnecessary - failed with error: %@",
                  error);
    expect(error).to.beNil;
}

- (void)testInstallPathAndContainerPathForApplication {
    expect([self.simulator bootIfNecessary:nil]).to.equal(YES);

    Application *app = [Application withBundlePath:testApp(SIM)];
    iOSReturnStatusCode code = [self.simulator installApp:app shouldUpdate:NO];
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
    NSArray *resources = @[[[Resources shared] TestRecorderDylibPath]];

    // shouldUpdate argument is broken, so we need to uninstall
    // When injecting resources, we should _always_ reinstall because
    // the version of the resources may have changed?
    Application *app = [Application withBundlePath:testApp(SIM)];

    expect([self.simulator waitForBootableState:nil]).to.beTruthy();
    expect([self.simulator bootIfNecessary:nil]).to.beTruthy();

    if ([self.simulator isInstalled:app.bundleID withError:nil]) {
        expect(
               [self.simulator uninstallApp:app.bundleID]
               ).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    iOSReturnStatusCode code = [self.simulator installApp:app
                                        resourcesToInject:resources
                                             shouldUpdate:NO];

    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    code = [self.simulator launchApp:[app bundleID]];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    __block NSString *version = nil;

    [[[FBRunLoopSpinner new] timeout:30] spinUntilTrue:^BOOL{
        version = [[Resources shared] TestRecorderVersionFromHost:@"127.0.0.1"];
        return version != nil;
    }];

    expect(version).to.beTruthy();
}

- (void)testUploadXCAppDataBundle {
    iOSReturnStatusCode code;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    Application *app = [Application withBundlePath:testApp(SIM)];

    expect([self.simulator waitForBootableState:nil]).to.beTruthy();
    expect([self.simulator bootIfNecessary:nil]).to.beTruthy();

    if (![self.simulator isInstalled:app.bundleID withError:nil]) {
        code = [self.simulator installApp:app resourcesToInject:nil shouldUpdate:NO];
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

- (void)testUploadXCAppDataBundleCLI {
    iOSReturnStatusCode code;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    Application *app = [Application withBundlePath:testApp(SIM)];

    expect([self.simulator waitForBootableState:nil]).to.beTruthy();
    expect([self.simulator bootIfNecessary:nil]).to.beTruthy();

    if (![self.simulator isInstalled:app.bundleID withError:nil]) {
        code = [self.simulator installApp:app resourcesToInject:nil shouldUpdate:NO];
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
    code = [CLI process:args];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    // works with app path
    args = @[kProgramName, @"upload-xcappdata",
             app.path, xcappdata,
             @"--device-id", self.simulator.uuid];
    code = [CLI process:args];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
}

@end
