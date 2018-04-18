
#import "TestCase.h"
#import "Device.h"
#import "Simulator.h"

@interface Simulator (TEST)

- (BOOL)launchSimulatorApp:(NSError *__autoreleasing *)error;
- (BOOL)waitForBootableState:(NSError *__autoreleasing *)error;
- (BOOL)waitForSimulatorState:(FBSimulatorState)state
                      timeout:(NSTimeInterval)timeout;
+ (FBSimulatorLifecycleCommands *)lifecycleCommandsWithFBSimulator:(FBSimulator *)fbSimulator;
- (FBSimulator *)fbSimulator;

@end

typedef BOOL (^CBXWaitUntilTrueBlock)(void);

@interface SimulatorTest : TestCase

@property(atomic, strong) Simulator *simulator;
@property(atomic, strong) id instanceMock;
@property(atomic, assign) NSError __autoreleasing **stubError;

@end

@implementation SimulatorTest

- (void)setUp {
    [super setUp];
    self.simulator = [Simulator withID:defaultSimUDID];
    self.instanceMock = OCMPartialMock(self.simulator);
    self.stubError = (NSError __autoreleasing **)[OCMArg anyPointer];
}

- (void)tearDown {
    OCMVerify(self.instanceMock);
    self.instanceMock = nil;
    self.simulator = nil;
    [super tearDown];
}

- (void)testLaunchSuccess {
    OCMExpect([self.instanceMock waitForBootableState:self.stubError]).andReturn(YES);
    OCMExpect([self.instanceMock launchSimulatorApp:self.stubError]).andReturn(YES);

    iOSReturnStatusCode actual = [Simulator launchSimulator:self.instanceMock];
    expect(actual).to.equal(iOSReturnStatusCodeEverythingOkay);
}

- (void)testLaunchWaitingForBootableStateFailed {
    OCMExpect([self.instanceMock waitForBootableState:self.stubError]).andReturn(NO);

    iOSReturnStatusCode actual = [Simulator launchSimulator:self.instanceMock];
    expect(actual).to.equal(iOSReturnStatusCodeGenericFailure);
}

- (void)testLaunchLaunchingSimulatorAppFailed {
    OCMExpect([self.instanceMock waitForBootableState:self.stubError]).andReturn(YES);
    OCMExpect([self.instanceMock launchSimulatorApp:self.stubError]).andReturn(NO);

    iOSReturnStatusCode actual = [Simulator launchSimulator:self.instanceMock];
    expect(actual).to.equal(iOSReturnStatusCodeGenericFailure);
}

- (void)testWaitForBootableStateWithStateBooted {
    OCMExpect([self.instanceMock state]).andReturn(FBSimulatorStateBooted);

    expect([self.instanceMock waitForBootableState:self.stubError]).to.beTruthy();
}

- (void)testWaitForBootableStateWithStateShutdown {
    OCMExpect([self.instanceMock state]).andReturn(FBSimulatorStateShutdown);

    expect([self.instanceMock waitForBootableState:self.stubError]).to.beTruthy();
}

- (void)testWaitForBootableStateWithStateBootingSuccess {
    OCMExpect([self.instanceMock state]).andReturn(FBSimulatorStateBooting);
    OCMExpect([self.instanceMock waitForSimulatorState:FBSimulatorStateBooted
                                       timeout:30]).andReturn(YES);

    expect([self.instanceMock waitForBootableState:self.stubError]).to.beTruthy();
}

- (void)testWaitForBootableStateWithStateBootingFailure {
    OCMExpect([self.instanceMock state]).andReturn(FBSimulatorStateBooting);
    OCMExpect([self.instanceMock waitForSimulatorState:FBSimulatorStateBooted
                                       timeout:30]).andReturn(NO);

    NSError __autoreleasing *error = nil;
    BOOL actual = [self.instanceMock waitForBootableState:&error];
    expect(actual).to.beFalsy();

    XCTAssertNotNil(error);

    XCTAssertEqualObjects([error localizedDescription],
                   @"Simulator never finished booting after 30 seconds");
}

- (void)testWaitForBootableWithStateShuttingDownSuccess {
    OCMExpect([self.instanceMock state]).andReturn(FBSimulatorStateShuttingDown);
    OCMExpect([self.instanceMock waitForSimulatorState:FBSimulatorStateShutdown
                                       timeout:30]).andReturn(YES);

    expect([self.instanceMock waitForBootableState:self.stubError]).to.beTruthy();
}

- (void)testWaitForBootableStateWithStateShuttingDownFailure {
    OCMExpect([self.instanceMock state]).andReturn(FBSimulatorStateShuttingDown);
    OCMExpect([self.instanceMock waitForSimulatorState:FBSimulatorStateShutdown
                                       timeout:30]).andReturn(NO);

    NSError __autoreleasing *error = nil;
    BOOL actual = [self.instanceMock waitForBootableState:&error];
    expect(actual).to.beFalsy();

    XCTAssertNotNil(error);

    XCTAssertEqualObjects([error localizedDescription],
                          @"Simulator never finished shutting down after 30 seconds");
}

- (void)testWaitForBootableStateWithStateCreatingSuccess {
    OCMExpect([self.instanceMock state]).andReturn(FBSimulatorStateCreating);
    OCMExpect([self.instanceMock waitForSimulatorState:FBSimulatorStateShutdown
                                       timeout:30]).andReturn(YES);

    expect([self.instanceMock waitForBootableState:self.stubError]).to.beTruthy();
}

- (void)testWaitForBootableStateWithStateCreatingFailure {
    OCMExpect([self.instanceMock state]).andReturn(FBSimulatorStateCreating);
    OCMExpect([self.instanceMock waitForSimulatorState:FBSimulatorStateShutdown
                                       timeout:30]).andReturn(NO);

    NSError __autoreleasing *error = nil;
    BOOL actual = [self.instanceMock waitForBootableState:&error];
    expect(actual).to.beFalsy();

    XCTAssertNotNil(error);

    XCTAssertTrue([[error localizedDescription]
                      containsString:@"Simulator never finished creating after 30 seconds"]);
}

- (void)testWaitForBootableStateBootingWithStateUnknown {
    OCMExpect([self.instanceMock state]).andReturn(FBSimulatorStateUnknown);

    NSError __autoreleasing *error = nil;
    BOOL actual = [self.instanceMock waitForBootableState:&error];
    expect(actual).to.beFalsy();

    XCTAssertNotNil(error);

    XCTAssertTrue([[error localizedDescription]
                   containsString:@"Could not boot simulator from this state:"]);
}

- (void)testSimulatorAppURL {
    NSURL *url = [Simulator simulatorAppURL];
    NSFileManager *manager = [NSFileManager defaultManager];
    expect([manager fileExistsAtPath:url.path]).to.beTruthy();
}

- (void)testEraseSimulator {
    id ClassMock = OCMClassMock([Simulator class]);
    OCMExpect([ClassMock killSimulatorApp]).andReturn(iOSReturnStatusCodeEverythingOkay);

    OCMExpect([self.instanceMock waitForSimulatorState:FBSimulatorStateShutdown
                                               timeout:30]).andReturn(YES);

    expect([ClassMock eraseSimulator:self.instanceMock]).to.equal(iOSReturnStatusCodeEverythingOkay);

    OCMVerifyAll(ClassMock);
    OCMVerifyAll(self.instanceMock);
}

@end
