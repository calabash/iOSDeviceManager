
#import "TestCase.h"
#import "Device.h"
#import "Simulator.h"

@interface Simulator (TEST)

- (BOOL)bootSimulatorIfNecessary:(NSError * __autoreleasing *) error;

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

- (void)testLaunchSuccess {
    Simulator *simulator = [Simulator withID:defaultSimUDID];
    id mock = OCMPartialMock(simulator);

    [[[mock stub]
            andReturnValue:@YES]
            bootSimulatorIfNecessary:((NSError __autoreleasing **)[OCMArg anyPointer])];

    iOSReturnStatusCode actual = [(Simulator *)mock launch];
    expect(actual).to.equal(iOSReturnStatusCodeEverythingOkay);
}

- (void)testLaunchFailure {
    Simulator *simulator = [Simulator withID:defaultSimUDID];
    id mock = OCMPartialMock(simulator);

    [[[mock stub]
            andReturnValue:@NO]
            bootSimulatorIfNecessary:((NSError __autoreleasing **)[OCMArg anyPointer])];

    iOSReturnStatusCode actual = [(Simulator *)mock launch];
    expect(actual).to.equal(iOSReturnStatusCodeInternalError);
}

@end
