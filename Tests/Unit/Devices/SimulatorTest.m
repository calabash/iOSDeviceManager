
#import "TestCase.h"
#import "Device.h"
#import "Simulator.h"

@interface Simulator (TEST)

- (BOOL)launchSimulatorApp:(NSError *__autoreleasing *)error;
- (BOOL)waitForBootableState:(NSError *__autoreleasing *)error;
- (BOOL)waitForSimulatorState:(FBiOSTargetState)state
                      timeout:(NSTimeInterval)timeout;
+ (FBSimulatorLifecycleCommands *)lifecycleCommandsWithFBSimulator:(FBSimulator *)fbSimulator;
- (FBSimulator *)fbSimulator;

@end

typedef BOOL (^CBXWaitUntilTrueBlock)(void);

@interface SimulatorTest : TestCase

@property(atomic, strong) Simulator *simulator;
//@property(atomic, strong) id instanceMock;
@property(atomic, assign) NSError __autoreleasing **stubError;

@end


@implementation SimulatorTest

- (void)setUp {
    [super setUp];
    self.simulator = [Simulator withID:defaultSimUDID];
    self.stubError = (NSError __autoreleasing **)[OCMArg anyPointer];
}

- (void)tearDown {
    self.simulator = nil;
    [super tearDown];
}

- (void)testLaunchSuccess {
    XCTAssertEqual([Simulator launchSimulator:self.simulator], iOSReturnStatusCodeEverythingOkay);
    XCTAssertEqual([self.simulator waitForBootableState:self.stubError], YES);
    XCTAssertEqual([self.simulator launchSimulatorApp:self.stubError], YES);
}

- (void)testEraseSimulatorSuccess {

    XCTAssertEqual([Simulator killSimulatorApp], iOSReturnStatusCodeEverythingOkay);

    NSError *error = nil;
    FBSimulatorShutdownStrategy *strategy = [FBSimulatorShutdownStrategy strategyWithSimulator:self.simulator.fbSimulator];
    XCTAssertNotEqual([[strategy shutdown] await:&error], nil);

    XCTAssertEqual([self.simulator waitForSimulatorState:FBiOSTargetStateShutdown timeout:30], YES);

    [[self.simulator.fbSimulator erase] await:&error];
    NSLog(@"Error is: %@\n", error);
    XCTAssertEqual(error, nil);
    XCTAssertEqual([Simulator eraseSimulator:self.simulator], iOSReturnStatusCodeEverythingOkay);
}

@end
