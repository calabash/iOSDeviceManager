
#import "TestCase.h"
#import "CodesignIdentity.h"
#import "ShellRunner.h"

@interface CodesignIdentity (TEST)

+ (NSArray<CodesignIdentity *> *)validIOSDeveloperIdentities;
+ (NSArray<CodesignIdentity *> *)validCodesigningIdentities;
+ (ShellResult *)askSecurityForValidCodesignIdentities;
- (BOOL)isEqualToCodesignIdentity:(CodesignIdentity *)other;

@end

@interface CodesignIdentityTest : TestCase

@end

@implementation CodesignIdentityTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testValidCodesigningIdentities {
    NSArray *array = [CodesignIdentity validCodesigningIdentities];

    expect(array).notTo.equal(nil);
    expect(array.count).notTo.equal(0);
}

- (void)testValidIOSDeveloperIdentities {
    NSArray *array = [CodesignIdentity validIOSDeveloperIdentities];

    expect(array).notTo.equal(nil);
    expect(array.count).notTo.equal(0);
}

@end

SpecBegin(CodesignIdentity)

#pragma mark - Instance Methods
__block CodesignIdentity *identity;

context(@"#initWithShasum:name:", ^{
    it(@"sets the name and identifier", ^{
        identity = [[CodesignIdentity alloc] initWithShasum:@"id" name:@"name"];
        expect(identity.shasum).to.equal(@"id");
        expect(identity.name).to.equal(@"name");
    });
});

context(@"equality", ^{
    __block CodesignIdentity *other;
    __block CodesignIdentity *same;

    before(^{
        identity = [[CodesignIdentity alloc] initWithShasum:@"id" name:@"name"];
        same = [[CodesignIdentity alloc] initWithShasum:@"id" name:@"name"];
        other = [[CodesignIdentity alloc]
                 initWithShasum:@"other id" name:@"other name"];
    });

    it(@"overrides isEqualToCodesignIdentity", ^{
        expect([identity isEqualToCodesignIdentity:identity]).to.equal(YES);
        expect([identity isEqualToCodesignIdentity:same]).to.equal(YES);
        expect([identity isEqualToCodesignIdentity:nil]).to.equal(NO);
        expect([identity isEqualToCodesignIdentity:other]).to.equal(NO);
    });

    it(@"overrides isEqual", ^{
        expect([identity isEqual:identity]).to.equal(YES);
        expect([identity isEqual:same]).to.equal(YES);
        expect([identity isEqual:nil]).to.equal(NO);
        expect([identity isEqual:other]).to.equal(NO);
        expect([identity isEqual:@"other"]).to.equal(NO);
    });

    it(@"overrides hash", ^{
        expect([identity hash] == [identity hash]).to.equal(YES);
        expect([identity hash] == [same hash]).to.equal(YES);
        expect([identity hash] == [other hash]).to.equal(NO);
        expect([identity hash] == [@"other" hash]).to.equal(NO);
    });

    it(@"implements NSCopying", ^{
        [[identity class] conformsToProtocol:@protocol(NSCopying)];

        NSMutableDictionary *hash = [@{} mutableCopy];
        hash[identity] = @"identity";
        hash[same] = @"same";
        hash[other] = @"other";

        expect(hash[identity]).to.equal(@"same");
        expect(hash[other]).to.equal(@"other");
    });
});

context(@"#isIOSDeveloperIdentity", ^{
    it(@"returns true if the name contains iPhone Developer", ^{
        NSString *shasum, *name;
        shasum = @"921D006C34510B86D66912F2C58344AC37A6B88E";
        name = @"iPhone Developer: Joshua Moody";
        identity = [[CodesignIdentity alloc] initWithShasum:shasum name:name];

        expect([identity isIOSDeveloperIdentity]).to.equal(YES);
    });

    it(@"returns false if the name does not contain iPhone Developer", ^{
        NSString *shasum, *name;
        shasum = @"FF46970BF4C91E7B88403EC1CFE723D43ABA64AB";
        name = @"Mac Developer: Karl Krukow (YTTN6Y2QS9)";
        identity = [[CodesignIdentity alloc] initWithShasum:shasum name:name];

        expect([identity isIOSDeveloperIdentity]).to.equal(NO);
    });
});

#pragma mark - Class Methods

context(@".identityForAppBundle:deviceId:", ^{
    __block id MockCodesignIdentity;
    __block CodesignIdentity *actual;
    __block NSString *deviceId = @"e8b4fbb3c8cc57969a517f930ae1957152048979";

    before(^{
        MockCodesignIdentity = OCMClassMock([CodesignIdentity class]);
    });

    after(^{
        OCMVerifyAll(MockCodesignIdentity);
    });

    it(@"returns a valid codesign identity given an app and device id", ^{
        actual = [CodesignIdentity
                  identityForAppBundle:testApp(ARM)
                  deviceId:deviceId];
        expect(actual).notTo.equal(nil);
        expect(actual.name).notTo.equal(nil);
        expect(actual.shasum).notTo.equal(nil);
        expect(actual.name.length).to.beGreaterThan(0);
        expect(actual.shasum.length).to.beGreaterThan(0);
    });

    it(@"returns nil if there are no valid identities for the app and device", ^{
        actual = [CodesignIdentity
                  identityForAppBundle:@"/path/to/invalid/bundle"
                  deviceId:deviceId];
        expect(actual).to.beNil;
    });
});

context(@".validIOSDeveloperIdentities", ^{
    __block id MockCodesignIdentity;
    __block NSArray<CodesignIdentity *> *actual;

    before(^{
        MockCodesignIdentity = OCMClassMock([CodesignIdentity class]);
    });

    after(^{
        OCMVerifyAll(MockCodesignIdentity);
    });

    it(@"returns an array of iPhone Developer identities", ^{
        NSArray<CodesignIdentity *> *identities;
        identities = @[[[CodesignIdentity alloc]
                        initWithShasum:@"" name:@"iPhone Developer"],
                       [[CodesignIdentity alloc] initWithShasum:@"" name:@"Mac Developer"]
                       ];

        OCMExpect([MockCodesignIdentity validCodesigningIdentities]
                  ).andReturn(identities);

        actual = [CodesignIdentity validIOSDeveloperIdentities];
        expect(actual.count).to.equal(1);
        expect(actual[0]).to.equal(identities[0]);
    });

    it(@"returns nil if there are no valid code sign identities", ^{
        OCMExpect([MockCodesignIdentity validCodesigningIdentities]
                  ).andReturn(nil);

        actual = [CodesignIdentity validIOSDeveloperIdentities];
        expect(actual).to.equal(nil);
    });
});

context(@".arrayOfValidCodesignIdentities", ^{
    __block id MockCodesignIdentity;
    __block NSArray<CodesignIdentity *> *actual;

    before(^{
        MockCodesignIdentity = OCMClassMock([CodesignIdentity class]);
    });

    after(^{
        OCMVerifyAll(MockCodesignIdentity);
    });

    it(@"returns an array of valid codesign identities", ^{
        ShellResult *result;
        result = [[Resources shared] successResultWithFakeSigningIdentities];

        OCMExpect(
                  [MockCodesignIdentity askSecurityForValidCodesignIdentities]
                  ).andReturn(result);

        CodesignIdentity *first, *last;
        first = [[CodesignIdentity alloc]
                 initWithShasum:@"921D006C34510B86D66912F2C58344AC37A6B88E"
                 name:@"Developer ID Application: Joshua Moody"];
        last = [[CodesignIdentity alloc]
                initWithShasum:@"FF46970BF4C91E7B88403EC1CFE723D43ABA64AB"
                name:@"Mac Developer: Karl Krukow (YTTN6Y2QS9)"];

        actual = [CodesignIdentity validCodesigningIdentities];

        expect(actual.count).to.equal(7);
        expect(actual[0]).to.equal(first);
        expect([actual lastObject]).to.equal(last);
    });

    it(@"returns nil if security could not find and valid identities", ^{
        OCMExpect([MockCodesignIdentity askSecurityForValidCodesignIdentities]
                  ).andReturn(nil);

        actual = [CodesignIdentity validCodesigningIdentities];
        expect(actual).to.equal(nil);
    });
});

context(@".askSecurityForValidCodesignIdentities", ^{
    __block id MockShellRunner;
    __block ShellResult *shellResult;
    __block ShellResult *actual;

    before(^{
        MockShellRunner = OCMClassMock([ShellRunner class]);
    });

    after(^{
        OCMVerifyAll(MockShellRunner);
    });

    it(@"returns the result of security find-identity -v -p codesigning", ^{
        shellResult = [[Resources shared] successResultMultiline];
        OCMExpect([MockShellRunner xcrun:OCMOCK_ANY timeout:30]).andReturn(shellResult);

        actual = [CodesignIdentity askSecurityForValidCodesignIdentities];
        expect(actual).to.equal(shellResult);
    });

    it(@"returns nil if the command timed out", ^{
        shellResult = [[Resources shared] timedOutResult];
        OCMExpect([MockShellRunner xcrun:OCMOCK_ANY timeout:30]).andReturn(shellResult);

        actual = [CodesignIdentity askSecurityForValidCodesignIdentities];
        expect(actual).to.equal(nil);
    });

    it(@"returns nil there was error calling find-identity", ^{
        shellResult = [[Resources shared] failedResult];
        OCMExpect([MockShellRunner xcrun:OCMOCK_ANY timeout:30]).andReturn(shellResult);

        actual = [CodesignIdentity askSecurityForValidCodesignIdentities];
        expect(actual).to.equal(nil);
    });
});

context(@".codeSignIdentityFromEnvironment", ^{
    __block id mockProcessInfo;
    __block NSMutableDictionary *environment;
    before(^{
        environment = [@{} mutableCopy];
        mockProcessInfo = OCMPartialMock([NSProcessInfo processInfo]);
        OCMExpect([mockProcessInfo environment]).andReturn(environment);
    });

    after(^{
        OCMVerifyAll(mockProcessInfo);
        [mockProcessInfo stopMocking];
    });

    it(@"returns codeSignIdentityFromEnvironment if it is defined", ^{
        environment[@"CODE_SIGN_IDENTITY"] = @"ME!";

        expect([CodesignIdentity codeSignIdentityFromEnvironment]).to.equal(@"ME!");
    });

    it(@"returns nil if CODE_SIGN_ENVIRONMENT is not defined", ^{
        expect([CodesignIdentity codeSignIdentityFromEnvironment]).to.equal(nil);
    });
});

SpecEnd
