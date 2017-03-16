
#import "TestCase.h"
#import "Device.h"
#import "Simulator.h"
#import "ShellRunner.h"
#import "MachClock.h"

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

+ (BOOL)waitWithTimeout:(NSTimeInterval)timeout
              untilTrue:(CBXWaitUntilTrueBlock)block {
    NSTimeInterval startTime = [[MachClock sharedClock] absoluteTime];
    NSTimeInterval endTime = startTime + timeout;

    BOOL blockIsTruthy = block();
    while(!blockIsTruthy && [[MachClock sharedClock] absoluteTime] < endTime) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
        blockIsTruthy = block();
    }

    return blockIsTruthy;
}

- (void)quitSimulators {
    ShellResult __unused *result = [ShellRunner xcrun:@[@"pkill", @"-9", @"Simulator"]
                                              timeout:10];

    __block NSArray<TestSimulator *> *simulators = [[Resources shared] simulators];
    [SimulatorTest waitWithTimeout:30 untilTrue:^BOOL{
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

    [SimulatorTest waitWithTimeout:30 untilTrue:^BOOL{
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
