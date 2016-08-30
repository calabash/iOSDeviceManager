
#import "TestCase.h"
#import "Codesigner.h"
#import "BundleResignerFactory.h"
#import "BundleResigner.h"

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

- (void)testReturnsNOAndPopulatesErrorIfFactoryCannotCreateResigner {
    id mockResignerFactory = OCMPartialMock([BundleResignerFactory shared]);
    OCMExpect(
              [mockResignerFactory resignerWithBundlePath:OCMOCK_ANY
                                               deviceUDID:OCMOCK_ANY
                                    signingIdentityString:OCMOCK_ANY]
              ).andReturn(nil);

    NSError *error = nil;

    Codesigner *signer;
    signer = [[Codesigner alloc] initWithCodeSignIdentity:@"identity"
                                               deviceUDID:@"udid"];

    BOOL actual = [signer signBundleAtPath:@"bundle path"
                                     error:&error];

    expect(actual).to.equal(NO);
    expect(error).notTo.equal(nil);
    expect(error.localizedDescription).to.equal(@"Could not resign with the given arguments");

    OCMVerifyAll(mockResignerFactory);
    [mockResignerFactory stopMocking];
}

- (void)testReturnsNOAndPopulatesErrorIfResigningFails {
    BundleResigner *resigner = [BundleResigner new];

    id mockResigner = OCMPartialMock(resigner);
    OCMExpect([mockResigner resign]).andReturn(NO);

    id mockResignerFactory = OCMPartialMock([BundleResignerFactory shared]);
    OCMExpect(
              [mockResignerFactory resignerWithBundlePath:OCMOCK_ANY
                                               deviceUDID:OCMOCK_ANY
                                    signingIdentityString:OCMOCK_ANY]
              ).andReturn(resigner);

    NSError *error = nil;

    Codesigner *signer;
    signer = [[Codesigner alloc] initWithCodeSignIdentity:@"identity"
                                               deviceUDID:@"udid"];

    BOOL actual = [signer signBundleAtPath:@"bundle path"
                                     error:&error];

    expect(actual).to.equal(NO);
    expect(error).notTo.equal(nil);
    expect(error.localizedDescription).to.equal(@"Code signing failed");

    OCMVerifyAll(mockResigner);
    OCMVerifyAll(mockResignerFactory);
    [mockResignerFactory stopMocking];
}

- (void)testUserPassNilErrorToSignBundleAtPath {
    id mockResignerFactory = OCMPartialMock([BundleResignerFactory shared]);
    OCMExpect(
              [mockResignerFactory resignerWithBundlePath:OCMOCK_ANY
                                               deviceUDID:OCMOCK_ANY
                                    signingIdentityString:OCMOCK_ANY]
              ).andReturn(nil);

    Codesigner *signer;
    signer = [[Codesigner alloc] initWithCodeSignIdentity:@"identity"
                                               deviceUDID:@"udid"];

    BOOL actual = [signer signBundleAtPath:@"bundle path"
                                     error:nil];

    expect(actual).to.equal(NO);

    OCMVerifyAll(mockResignerFactory);
    [mockResignerFactory stopMocking];
}

@end
