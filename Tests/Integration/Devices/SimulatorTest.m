
#import "TestCase.h"
#import "Device.h"
#import "Simulator.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "MachClock.h"
#import <FBControlCore/FBControlCore.h>
#import "Application.h"

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

@end
