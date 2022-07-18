
#import "TestCase.h"
#import "Device.h"
#import "Simulator.h"

@interface Simulator (TEST)

- (BOOL)boot;
- (BOOL)waitForSimulatorState:(FBiOSTargetState)state
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
    OCMStub([self.instanceMock boot]).andReturn(YES);
    
    iOSReturnStatusCode actual = [Simulator launchSimulator:self.instanceMock];
    expect(actual).to.equal(iOSReturnStatusCodeEverythingOkay);
}

- (void)testLaunchWaitingForBootableStateFailed {
    OCMStub([self.instanceMock boot]).andReturn(NO);

    iOSReturnStatusCode actual = [Simulator launchSimulator:self.instanceMock];
    expect(actual).to.equal(iOSReturnStatusCodeGenericFailure);
}

- (void)testLaunchLaunchingSimulatorAppFailed {
    OCMStub([self.instanceMock waitForSimulatorState:FBiOSTargetStateBooted timeout:30]).andReturn(YES);
    OCMStub([self.instanceMock boot]).andReturn(NO);

    iOSReturnStatusCode actual = [Simulator launchSimulator:self.instanceMock];
    expect(actual).to.equal(iOSReturnStatusCodeGenericFailure);
}

- (void)testWaitForBootableStateWithStateBooted {
    OCMStub([self.instanceMock state]).andReturn(FBiOSTargetStateBooted);

    expect([self.instanceMock boot]).to.beTruthy();
}

- (void)testWaitForBootableStateWithStateShutdown {
    OCMStub([self.instanceMock state]).andReturn(FBiOSTargetStateShutdown);
    
    expect([self.instanceMock boot]).to.beTruthy();
}


- (void)testWaitForBootableStateWithStateBootingSuccess {
    OCMStub([self.instanceMock state]).andReturn(FBiOSTargetStateBooting);
    OCMStub([self.instanceMock waitForSimulatorState:FBiOSTargetStateBooted
                                       timeout:30]).andReturn(YES);

    expect([self.instanceMock boot]).to.beTruthy();
}


- (void)testWaitForBootableStateWithStateBootingFailure {
    OCMStub([self.instanceMock state]).andReturn(FBiOSTargetStateBooting);
    OCMStub([self.instanceMock waitForSimulatorState:(FBiOSTargetState)FBiOSTargetStateBooted
                                       timeout:30]).andReturn(NO);

    expect([self.instanceMock boot]).to.beFalsy();
}


- (void)testWaitForBootableWithStateShuttingDownSuccess {
    OCMStub([self.instanceMock state]).andReturn(FBiOSTargetStateShuttingDown);
    OCMStub([self.instanceMock waitForSimulatorState:FBiOSTargetStateShutdown
                                       timeout:30]).andReturn(YES);

    expect([self.instanceMock boot]).to.beTruthy();
}

- (void)testWaitForBootableStateWithStateShuttingDownFailure {
    OCMStub([self.instanceMock state]).andReturn(FBiOSTargetStateShuttingDown);
    OCMStub([self.instanceMock waitForSimulatorState:FBiOSTargetStateShutdown
                                       timeout:30]).andReturn(NO);

    expect([self.instanceMock boot]).to.beFalsy();
}

- (void)testWaitForBootableStateWithStateCreatingSuccess {
    OCMStub([self.instanceMock state]).andReturn(FBiOSTargetStateCreating);
    OCMStub([self.instanceMock waitForSimulatorState:FBiOSTargetStateShutdown
                                       timeout:30]).andReturn(YES);

    expect([self.instanceMock boot]).to.beTruthy();
}

- (void)testWaitForBootableStateWithStateCreatingFailure {
    OCMStub([self.instanceMock state]).andReturn(FBiOSTargetStateCreating);
    OCMStub([self.instanceMock waitForSimulatorState:FBiOSTargetStateShutdown
                                       timeout:30]).andReturn(NO);

    expect([self.instanceMock boot]).to.beTruthy();
}

- (void)testWaitForBootableStateBootingWithStateUnknown {
    OCMStub([self.instanceMock state]).andReturn(FBiOSTargetStateUnknown);

    expect([self.instanceMock boot]).to.beTruthy();
}

- (void)testEraseSimulatorSuccess {

    XCTAssertEqual([Simulator killSimulatorApp], iOSReturnStatusCodeEverythingOkay);

    NSError *error = nil;
    SimDevice *simDevice = [self.simulator.fbSimulator device];
    if ([self.simulator.fbSimulator state] != FBiOSTargetStateShutdown) {
        XCTAssertEqual([simDevice shutdownWithError:&error], YES);
        XCTAssertEqual([self.simulator waitForSimulatorState:FBiOSTargetStateShutdown timeout:30], YES);
    }

    [[self.simulator.fbSimulator erase] await:&error];
    NSLog(@"Error is: %@\n", error);
    XCTAssertEqual(error, nil);
    XCTAssertEqual([Simulator eraseSimulator:self.simulator], iOSReturnStatusCodeEverythingOkay);
}

- (void)testEraseSimulatorShutdownFailure {
    id ClassMock = OCMClassMock([Simulator class]);
    id fbSimMock = OCMPartialMock(self.simulator.fbSimulator);
    
    
    OCMExpect([ClassMock killSimulatorApp]).andReturn(iOSReturnStatusCodeEverythingOkay);
    OCMExpect([[fbSimMock device] shutdownWithError:[OCMArg anyObjectRef]]).andReturn(NO);
    OCMExpect([self.instanceMock waitForSimulatorState:FBiOSTargetStateShutdown
                                               timeout:30]).andReturn(NO);
    OCMExpect([[fbSimMock erase] await:[OCMArg anyObjectRef]]).andReturn(YES);
    
    expect([Simulator eraseSimulator:self.instanceMock]).to.equal(iOSReturnStatusCodeInternalError);
    
    OCMVerifyAll(ClassMock);
    OCMVerifyAll(self.instanceMock);
}

//- (void)testEraseSimulatorEraseFailure {
//    id ClassMock = OCMClassMock([Simulator class]);
//    id FBSimulatorShutdownStrategyClassMock = OCMClassMock([FBSimulatorShutdownStrategy class]);
//    id fbSimMock = OCMPartialMock(self.simulator.fbSimulator);
//    
//    
//    OCMExpect([ClassMock killSimulatorApp]).andReturn(iOSReturnStatusCodeEverythingOkay);
//    OCMExpect([[FBSimulatorShutdownStrategyClassMock shutdown] await:[OCMArg anyObjectRef]]).andReturn(YES);
//    OCMExpect([self.instanceMock waitForSimulatorState:FBiOSTargetStateShutdown
//                                               timeout:30]).andReturn(YES);
//    OCMExpect([[fbSimMock erase] await:[OCMArg anyObjectRef]]).andReturn(NO);
//    
//    expect([Simulator eraseSimulator:self.instanceMock]).to.equal(iOSReturnStatusCodeInternalError);
//    
//    OCMVerifyAll(ClassMock);
//    OCMVerifyAll(self.instanceMock);
//}

- (void)testEraseSimulatorFailure {
    id ClassMock = OCMClassMock([Simulator class]);
    id fbSimMock = OCMPartialMock(self.simulator.fbSimulator);
    
    
    OCMExpect([ClassMock killSimulatorApp]).andReturn(iOSReturnStatusCodeEverythingOkay);
    OCMExpect([[fbSimMock device] shutdownWithError:[OCMArg anyObjectRef]]).andReturn(NO);
    OCMExpect([self.instanceMock waitForSimulatorState:FBiOSTargetStateShutdown
                                               timeout:30]).andReturn(NO);
    OCMExpect([[fbSimMock erase] await:[OCMArg anyObjectRef]]).andReturn(NO);
    
    expect([Simulator eraseSimulator:self.instanceMock]).to.equal(iOSReturnStatusCodeInternalError);
    
    OCMVerifyAll(ClassMock);
    OCMVerifyAll(self.instanceMock);
}
@end
