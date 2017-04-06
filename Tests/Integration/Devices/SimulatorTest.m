
#import "TestCase.h"
#import "Device.h"
#import "Simulator.h"
#import "ShellRunner.h"
#import "MachClock.h"
#import <FBControlCore/FBControlCore.h>
#import "Application.h"

@interface Simulator (TEST)

- (FBSimulator *)fbSimulator;
- (BOOL)bootSimulatorIfNecessary:(NSError * __autoreleasing *) error;
+ (FBSimulatorLifecycleCommands *)lifecycleCommandsWithFBSimulator:(FBSimulator *)fbSimulator;

@end

@interface SimulatorTest : TestCase

@end

@implementation SimulatorTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)quitSimulators {
    ShellResult __unused *result = [ShellRunner xcrun:@[@"pkill", @"-9", @"Simulator"]
                                              timeout:10];

    __block NSArray<TestSimulator *> *simulators = [[Resources shared] simulators];
    [[[FBRunLoopSpinner new] timeout:30] spinUntilTrue:^BOOL{

        NSMutableArray *mutable = [NSMutableArray arrayWithCapacity:100];
        for (TestSimulator *simulator in simulators) {
            if (![[simulator stateString] isEqualToString:@"Shutdown"]) {
                [mutable addObject:simulator];
            }
        }

        simulators = [NSArray arrayWithArray:mutable];

        return [simulators count] == 0;
    }];
}

- (void)testBootSimulatorIfNecessarySuccess {

    [self quitSimulators];

    NSError *error = nil;

    Simulator *simulator = [Simulator withID:defaultSimUDID];

    // Boot required
    XCTAssertTrue([simulator bootSimulatorIfNecessary:&error]);
    expect(error).to.beNil;

    [[[FBRunLoopSpinner new] timeout:30] spinUntilTrue:^BOOL{
      return simulator.fbSimulator.state == FBSimulatorStateBooted;
    }];

    // Boot not required
    XCTAssertTrue([simulator bootSimulatorIfNecessary:&error]);
    expect(error).to.beNil;
}

- (void)testBootSimulatorIfNecessaryFailure {
    [self quitSimulators];

    Simulator *simulator = [Simulator withID:defaultSimUDID];
    FBSimulatorLifecycleCommands *commands;
    commands = [FBSimulatorLifecycleCommands commandsWithSimulator:simulator.fbSimulator];
    id mockCommands = OCMPartialMock(commands);
    [[[mockCommands stub] andReturnValue:@NO] bootSimulator:[OCMArg any]
                                                      error:((NSError __autoreleasing **)[OCMArg anyPointer])];

    id SimulatorMock = OCMClassMock([Simulator class]);
    OCMExpect(
              [SimulatorMock lifecycleCommandsWithFBSimulator:simulator.fbSimulator]
              ).andReturn(mockCommands);

    NSError *error = nil;

    XCTAssertFalse([simulator bootSimulatorIfNecessary:&error]);
    OCMVerifyAll(SimulatorMock);
    OCMVerifyAll(mockCommands);
}

- (void)testInstallPathAndContainerPathForApplication {
    Simulator *sim = [Simulator withID:defaultSimUDID];
    if (sim.fbSimulator.state != FBSimulatorStateBooted)    {
        expect([sim launch]).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    Application *app = [Application withBundlePath:testApp(SIM)];
    [sim installApp:app shouldUpdate:NO];
    NSString *bundleIdentifier = @"sh.calaba.TestApp";
    NSString *installPath = [sim installPathForApplication:bundleIdentifier];
    NSString *containerPath = [sim containerPathForApplication:bundleIdentifier];

    expect(installPath).notTo.beNil;
    expect([installPath containsString:sim.uuid]).to.beTruthy;
    expect([installPath containsString:@"data/Containers/Bundle/Application"]).to.beTruthy;
    expect([installPath containsString:@"TestApp.app"]).to.beTruthy;

    expect(containerPath).notTo.beNil;
    expect([containerPath containsString:sim.uuid]).to.beTruthy;
    expect([containerPath containsString:@"data/Containers/Data/Application"]).to.beTruthy;

    NSString *plistName = @".com.apple.mobile_container_manager.metadata.plist";
    NSString *plistPath = [containerPath stringByAppendingPathComponent:plistName];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    expect(dictionary[@"MCMMetadataIdentifier"]).to.equal(bundleIdentifier);

    bundleIdentifier = @"com.example.NoSuchApp";
    installPath = [sim installPathForApplication:bundleIdentifier];
    containerPath = [sim containerPathForApplication:bundleIdentifier];

    expect(installPath).to.beNil;
    expect(containerPath).to.beNil;

    [sim kill];
}

@end
