
#import "TestCase.h"
#import "Device.h"
#import "Simulator.h"

@interface Simulator (TEST)

- (BOOL)waitForBootableState:(NSError *__autoreleasing *)error;
- (BOOL)bootIfNecessary:(NSError * __autoreleasing *) error;
- (BOOL)bootWithFBSimulator:(FBSimulator *)simulator
                      error:(NSError * __autoreleasing*) error;
- (BOOL)waitForSimulatorState:(FBSimulatorState)state
                      timeout:(NSTimeInterval)timeout;
+ (FBSimulatorLifecycleCommands *)lifecycleCommandsWithFBSimulator:(FBSimulator *)fbSimulator;
- (FBSimulator *)fbSimulator;

@end

typedef BOOL (^CBXWaitUntilTrueBlock)();

@interface SimulatorTest : TestCase

@property(atomic, strong) Simulator *simulator;
@property(atomic, strong) id mock;
@property(atomic, assign) NSError __autoreleasing **stubError;

@end

@implementation SimulatorTest

- (void)setUp {
    [super setUp];
    self.simulator = [Simulator withID:defaultSimUDID];
    self.mock = OCMPartialMock(self.simulator);
    self.stubError = (NSError __autoreleasing **)[OCMArg anyPointer];
}

- (void)tearDown {
    OCMVerify(self.mock);
    self.mock = nil;
    self.simulator = nil;
    [super tearDown];
}

- (void)testBootSimulatorIfNecessaryCouldPrepareWithSuccessfulLaunch {
    OCMExpect([self.mock waitForBootableState:self.stubError]).andReturn(YES);
    OCMExpect([self.mock bootWithFBSimulator:self.simulator.fbSimulator
                                       error:self.stubError]).andReturn(YES);

    expect([self.mock bootIfNecessary:self.stubError]).to.beTruthy();
}

- (void)testBootSimulatorIfNecessaryCouldPrepareWithFailedLaunch {
    OCMExpect([self.mock waitForBootableState:self.stubError]).andReturn(YES);
    OCMExpect([self.mock bootWithFBSimulator:self.simulator.fbSimulator
                                       error:self.stubError]).andReturn(NO);

    expect([self.mock bootIfNecessary:self.stubError]).to.beFalsy;
}

- (void)testBootSimulatorIfNecessaryCouldNotPrepare {
    OCMExpect([self.mock waitForBootableState:self.stubError]).andReturn(NO);

    expect([self.mock bootIfNecessary:self.stubError]).to.beFalsy();
}

- (void)testLaunchSuccess {
    OCMExpect([self.mock bootIfNecessary:self.stubError]).andReturn(YES);

    iOSReturnStatusCode actual = [(Simulator *)self.mock launch];
    expect(actual).to.equal(iOSReturnStatusCodeEverythingOkay);
}

- (void)testLaunchFailure {
    OCMExpect([self.mock bootIfNecessary:self.stubError]).andReturn(NO);

    iOSReturnStatusCode actual = [(Simulator *)self.mock launch];
    expect(actual).to.equal(iOSReturnStatusCodeInternalError);
}

- (void)testPrepareSimulatorForBootingWithStateBooted {
    OCMExpect([self.mock state]).andReturn(FBSimulatorStateBooted);

    expect([self.mock waitForBootableState:self.stubError]).to.beTruthy();
}

- (void)testPrepareSimulatorForBootingWithStateShutdown {
    OCMExpect([self.mock state]).andReturn(FBSimulatorStateShutdown);

    expect([self.mock waitForBootableState:self.stubError]).to.beTruthy();
}

- (void)testPrepareSimulatorForBootingWithStateBootingSuccess {
    OCMExpect([self.mock state]).andReturn(FBSimulatorStateBooting);
    OCMExpect([self.mock waitForSimulatorState:FBSimulatorStateBooted
                                       timeout:30]).andReturn(YES);

    expect([self.mock waitForBootableState:self.stubError]).to.beTruthy();
}

- (void)testPrepareSimulatorForBootingWithStateBootingFailure {
    OCMExpect([self.mock state]).andReturn(FBSimulatorStateBooting);
    OCMExpect([self.mock waitForSimulatorState:FBSimulatorStateBooted
                                       timeout:30]).andReturn(NO);

    NSError __autoreleasing *error = nil;
    BOOL actual = [self.mock waitForBootableState:&error];
    expect(actual).to.beFalsy();

    XCTAssertNotNil(error);

    XCTAssertEqualObjects([error localizedDescription],
                   @"Simulator never finished booting after 30 seconds");
}

- (void)testPrepareSimulatorForBootingWithStateShuttingDownSuccess {
    OCMExpect([self.mock state]).andReturn(FBSimulatorStateShuttingDown);
    OCMExpect([self.mock waitForSimulatorState:FBSimulatorStateShutdown
                                       timeout:30]).andReturn(YES);

    expect([self.mock waitForBootableState:self.stubError]).to.beTruthy();
}

- (void)testPrepareSimulatorForBootingWithShuttingDownFailure {
    OCMExpect([self.mock state]).andReturn(FBSimulatorStateShuttingDown);
    OCMExpect([self.mock waitForSimulatorState:FBSimulatorStateShutdown
                                       timeout:30]).andReturn(NO);

    NSError __autoreleasing *error = nil;
    BOOL actual = [self.mock waitForBootableState:&error];
    expect(actual).to.beFalsy();

    XCTAssertNotNil(error);

    XCTAssertEqualObjects([error localizedDescription],
                          @"Simulator never finished shutting down after 30 seconds");
}

- (void)testPrepareSimulatorForBootingWithStateCreating {
    OCMExpect([self.mock state]).andReturn(FBSimulatorStateCreating);

    NSError __autoreleasing *error = nil;
    BOOL actual = [self.mock waitForBootableState:&error];
    expect(actual).to.beFalsy();

    XCTAssertNotNil(error);

    XCTAssertTrue([[error localizedDescription]
                      containsString:@"Could not boot simulator from this state:"]);
}

- (void)testPrepareSimulatorForBootingWithStateUnknown {
    OCMExpect([self.mock state]).andReturn(FBSimulatorStateUnknown);

    NSError __autoreleasing *error = nil;
    BOOL actual = [self.mock waitForBootableState:&error];
    expect(actual).to.beFalsy();

    XCTAssertNotNil(error);

    XCTAssertTrue([[error localizedDescription]
                   containsString:@"Could not boot simulator from this state:"]);
}

@end
