
#import "TestCase.h"
#import "Device.h"
#import "Simulator.h"

@interface Simulator (TEST)

- (BOOL)waitForBootableState:(NSError *__autoreleasing *)error;
- (BOOL)waitForSimulatorState:(FBSimulatorState)state
                      timeout:(NSTimeInterval)timeout;
+ (FBSimulatorLifecycleCommands *)lifecycleCommandsWithFBSimulator:(FBSimulator *)fbSimulator;
- (FBSimulator *)fbSimulator;

@end

typedef BOOL (^CBXWaitUntilTrueBlock)(void);

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

- (void)testLaunchSuccess {
    OCMExpect([self.mock waitForBootableState:self.stubError]).andReturn(YES);

    iOSReturnStatusCode actual = [(Simulator *)self.mock launch];
    expect(actual).to.equal(iOSReturnStatusCodeEverythingOkay);
}

- (void)testLaunchFailure {
    OCMExpect([self.mock waitForBootableState:self.stubError]).andReturn(NO);

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
                      containsString:@"Simulator never finished creating after 30 seconds"]);
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

- (void)testSimulatorAppURL {
    NSURL *url = [Simulator simulatorAppURL];
    NSFileManager *manager = [NSFileManager defaultManager];
    expect([manager fileExistsAtPath:url.path]).to.beTruthy();
}

@end