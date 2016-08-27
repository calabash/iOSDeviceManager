
#import "TestCase.h"
#import "Codesigner.h"

@interface Codesigner (TEST)

@property(copy) NSString *deviceUDID;

@end

@interface CodesignerTest : TestCase

@end

@implementation CodesignerTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInitCodesignerThatCanSign {
    Codesigner *signer;
    signer = [[Codesigner alloc] initWithCodeSignIdentity:@"identity"
                                               deviceUDID:@"udid"];

    expect([signer deviceUDID]).to.equal(@"udid");
    expect([signer codeSignIdentity]).to.equal(@"identity");
}

- (void)testSignerThatCannotSign {
    Codesigner *signer = [Codesigner signerThatCannotSign];
    expect([signer deviceUDID]).to.equal(nil);
    expect([signer codeSignIdentity]).to.equal(nil);
}

@end
