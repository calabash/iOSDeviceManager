
#import "TestCase.h"
#import "Device.h"
#import "Simulator.h"
#import "ShellRunner.h"
#import "MachClock.h"
#import <FBControlCore/FBControlCore.h>

@interface Simulator (TEST)

- (FBSimulator *)fbSimulator;
- (BOOL)bootSimulatorIfNecessary:(NSError * __autoreleasing *) error;
+ (FBSimulatorLifecycleCommands *)lifecycleCommandsWithFBSimulator:(FBSimulator *)fbSimulator;

@end

typedef BOOL (^CBXWaitUntilTrueBlock)();

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

@end
