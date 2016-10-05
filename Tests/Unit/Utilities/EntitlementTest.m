
#import "TestCase.h"
#import "Entitlement.h"

@interface Entitlement (TEST)
- (BOOL)hasNSArrayValue;
- (BOOL)hasNSStringValue;

@end

@interface EntitlementTest : TestCase

@end

@implementation EntitlementTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInitWithStringValue {
    Entitlement *entitlement = [[Entitlement alloc] initWithKey:@"key"
                                                          value:@"value"];
    expect(entitlement.key).to.equal(@"key");
    expect(entitlement.value).to.equal(@"value");
    expect([entitlement hasNSArrayValue]).to.equal(NO);
    expect([entitlement hasNSStringValue]).to.equal(YES);

}

- (void)testInitWithArrayValue {
    Entitlement *entitlement = [[Entitlement alloc] initWithKey:@"key"
                                                          value:@[@"value"]];
    expect(entitlement.key).to.equal(@"key");
    expect(entitlement.value).to.equal(@[@"value"]);
    expect([entitlement hasNSArrayValue]).to.equal(YES);
    expect([entitlement hasNSStringValue]).to.equal(NO);
}

- (void)testConvenienceConstructor {
    Entitlement *entitlement = [Entitlement entitlementWithKey:@"key"
                                                         value:@"value"];
    expect(entitlement.key).to.equal(@"key");
    expect(entitlement.value).to.equal(@"value");
    expect([entitlement hasNSStringValue]).to.equal(YES);
}

@end

SpecBegin(Entitlement)

__block Entitlement *profile;
__block Entitlement *app;
__block EntitlementComparisonResult actual;

/*
 // Reject
 ProfileDoesNotHaveRequiredKey = -1,

 AppNorProfileHasKey = 0,

 // Accept
 ProfileHasKeyExactly = 1,
 ProfileHasKey = 100,
 ProfileHasUnRequiredKey = 1000,
 */

// app: string, prof: array,  result: match
// app: string, prof: array,  result: fail
// app: array,  prof: array,  result: match
// app: array,  prof: array,  result: fail
// app: array,  prof: string, result: match
// app: array,  prof: string, result: fail

context(@".compareProfileEntitlement:appEntitlement:", ^{
    it(@"returns ProfileDoesNotHaveRequiredKey when profile is missing key", ^{
        profile = [Entitlement entitlementWithKey:@"key" value:nil];
        app = [Entitlement entitlementWithKey:@"key" value:@"value"];
        actual = [Entitlement compareProfileEntitlement:profile
                                         appEntitlement:app];

        expect(actual).to.equal(ProfileDoesNotHaveRequiredKey);
    });

    it(@"returns AppNorProfileHasKey when neither profile or app has the key", ^{
        profile = [Entitlement entitlementWithKey:@"key" value:nil];
        app = [Entitlement entitlementWithKey:@"key" value:nil];
        actual = [Entitlement compareProfileEntitlement:profile
                                         appEntitlement:app];

        expect(actual).to.equal(AppNorProfileHasKey);
    });

    it(@"returns ProfileHasUnRequiredKey when the profile has an unnecessary key", ^{
        profile = [Entitlement entitlementWithKey:@"key" value:@"value"];
        app = [Entitlement entitlementWithKey:@"key" value:nil];
        actual = [Entitlement compareProfileEntitlement:profile
                                         appEntitlement:app];

        expect(actual).to.equal(ProfileHasUnRequiredKey);
    });

    context(@"comparing string values", ^{
        it(@"returns ProfileHasKeyExactly when the values are equal", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@"value"];
            app = [Entitlement entitlementWithKey:@"key" value:@"value"];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app];

            expect(actual).to.equal(ProfileHasKeyExactly);
        });

        it(@"returns ProfileHasKey when the values are not equal", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@"b"];
            app = [Entitlement entitlementWithKey:@"key" value:@"a"];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app];

            expect(actual).to.equal(ProfileHasKey);
        });
    });

    context(@"comparing array values", ^{
        it(@"returns ProfileDoesNotHaveRequiredKey if the profile has fewer items", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@[@"a"]];
            app = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b"]];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app];

            expect(actual).to.equal(ProfileDoesNotHaveRequiredKey);
        });

        it(@"returns ProfileHasKey if the profile has more items", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b"]];
            app = [Entitlement entitlementWithKey:@"key" value:@[@"a"]];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app];

            expect(actual).to.equal(ProfileHasKey);
        });

        it(@"returns ProfileHasKeyExactly if the profile has the same items", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b"]];
            app = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b"]];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app];

            expect(actual).to.equal(ProfileHasKeyExactly);
        });

        it(@"returns ProfileHasKey if the profile has the number of items", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b"]];
            app = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"c"]];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app];

            expect(actual).to.equal(ProfileHasKey);
        });
    });

    context(@"compare mixed values", ^{
        it(@"returns ProfileHasKey if profile value is '*' and app value is array", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@"*"];
            app = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b", @"c"]];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app];

            expect(actual).to.equal(ProfileHasKey);
        });

        it(@"returns ProfileDoesNotHaveRequiredKey if profile value is string (not '*') and app value is array", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@"a"];
            app = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b", @"c"]];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app];

            expect(actual).to.equal(ProfileDoesNotHaveRequiredKey);
        });

        it (@"returns ProfileDoesNotHaveRequiredKey if app value is '*' and profile value is array", ^{
            profile = [Entitlement entitlementWithKey:@"key"
                                                value:@[@"a", @"b"]];
            app = [Entitlement entitlementWithKey:@"key" value:@"*"];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app];

            expect(actual).to.equal(ProfileDoesNotHaveRequiredKey);
        });

        it(@"returns ProfileHasKey if profile value is array and app value is a string in that array", ^{
            profile = [Entitlement entitlementWithKey:@"key"
                                                value:@[@"a", @"b"]];
            app = [Entitlement entitlementWithKey:@"key" value:@"b"];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app];

            expect(actual).to.equal(ProfileHasKey);
        });

        it(@"returns ProfileDoesNotHaveRequiredKey if profile value is array and app value is string not in that array", ^{
            profile = [Entitlement entitlementWithKey:@"key"
                                                value:@[@"a", @"b"]];
            app = [Entitlement entitlementWithKey:@"key" value:@"x"];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app];

            expect(actual).to.equal(ProfileDoesNotHaveRequiredKey);
        });
    });
});
SpecEnd

