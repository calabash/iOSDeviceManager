
#import "TestCase.h"
#import "Entitlement.h"

@interface Entitlement (TEST)

+ (EntitlementComparisonResult)compareAssociatedDomains:(Entitlement *)profileEntitlement
                                         appEntitlement:(Entitlement *)appEntitlement;

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

context(@".compareProfileEntitlement:appEntitlement:isAssociatedDomainsKey:", ^{
    it(@"returns ProfileDoesNotHaveRequiredKey when profile is missing key", ^{
        profile = [Entitlement entitlementWithKey:@"key" value:nil];
        app = [Entitlement entitlementWithKey:@"key" value:@"value"];
        actual = [Entitlement compareProfileEntitlement:profile
                                         appEntitlement:app
                                 isAssociatedDomainsKey:NO];

        expect(actual).to.equal(ProfileDoesNotHaveRequiredKey);
    });

    it(@"returns ProfileDoesNotHaveRequiredKey when there are mix values outside of an associated domains key comparison", ^{
        profile = [Entitlement entitlementWithKey:@"key" value:@[@"a"]];
        app = [Entitlement entitlementWithKey:@"key" value:@"value"];
        actual = [Entitlement compareProfileEntitlement:profile
                                         appEntitlement:app
                                 isAssociatedDomainsKey:NO];

        expect(actual).to.equal(ProfileDoesNotHaveRequiredKey);
    });

    it(@"compares associated-domains in a special way", ^{
        profile = [Entitlement entitlementWithKey:@"key" value:@[@"a"]];
        app = [Entitlement entitlementWithKey:@"key" value:@"value"];

        id MockEntitlement = OCMClassMock([Entitlement class]);
        OCMExpect(
                  [MockEntitlement compareAssociatedDomains:profile
                                             appEntitlement:app]
                  ).andReturn(ProfileHasKeyExactly);

        actual = [Entitlement compareProfileEntitlement:profile
                                         appEntitlement:app
                                 isAssociatedDomainsKey:YES];

        expect(actual).to.equal(ProfileHasKeyExactly);

        OCMVerifyAll(MockEntitlement);
    });

    it(@"returns AppNorProfileHasKey when neither profile or app has the key", ^{
        profile = [Entitlement entitlementWithKey:@"key" value:nil];
        app = [Entitlement entitlementWithKey:@"key" value:nil];
        actual = [Entitlement compareProfileEntitlement:profile
                                         appEntitlement:app
                                 isAssociatedDomainsKey:NO];

        expect(actual).to.equal(AppNorProfileHasKey);
    });

    it(@"returns ProfileHasUnRequiredKey when the profile has an unnecessary key", ^{
        profile = [Entitlement entitlementWithKey:@"key" value:@"value"];
        app = [Entitlement entitlementWithKey:@"key" value:nil];
        actual = [Entitlement compareProfileEntitlement:profile
                                         appEntitlement:app
                                 isAssociatedDomainsKey:NO];

        expect(actual).to.equal(ProfileHasUnRequiredKey);
    });

    context(@"comparing string values", ^{
        it(@"returns ProfileHasKeyExactly when the values are equal", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@"value"];
            app = [Entitlement entitlementWithKey:@"key" value:@"value"];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app
                                     isAssociatedDomainsKey:NO];

            expect(actual).to.equal(ProfileHasKeyExactly);
        });

        it(@"returns ProfileHasKey when the values are not equal", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@"b"];
            app = [Entitlement entitlementWithKey:@"key" value:@"a"];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app
                                     isAssociatedDomainsKey:NO];

            expect(actual).to.equal(ProfileHasKey);
        });
    });

    context(@"comparing array values", ^{
        it(@"returns ProfileDoesNotHaveRequiredKey if the profile has fewer items", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@[@"a"]];
            app = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b"]];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app
                                     isAssociatedDomainsKey:NO];

            expect(actual).to.equal(ProfileDoesNotHaveRequiredKey);
        });

        it(@"returns ProfileHasKey if the profile has more items", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b"]];
            app = [Entitlement entitlementWithKey:@"key" value:@[@"a"]];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app
                                     isAssociatedDomainsKey:NO];

            expect(actual).to.equal(ProfileHasKey);
        });

        it(@"returns ProfileHasKeyExactly if the profile has the same items", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b"]];
            app = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b"]];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app
                                     isAssociatedDomainsKey:NO];

            expect(actual).to.equal(ProfileHasKeyExactly);
        });

        it(@"returns ProfileHasKey if the profile has the number of items", ^{
            profile = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b"]];
            app = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"c"]];
            actual = [Entitlement compareProfileEntitlement:profile
                                             appEntitlement:app
                                     isAssociatedDomainsKey:NO];

            expect(actual).to.equal(ProfileHasKey);
        });
    });

    context(@"compareAssociatedDomains:appEntitlement", ^{
        context(@"profile has array value", ^{
            context(@"app value is an array", ^{
                it(@"calls back to compareProfileEntitlement:", ^{
                    profile = [Entitlement entitlementWithKey:@"key"
                                                        value:@[@"a", @"b"]];
                    app = [Entitlement entitlementWithKey:@"key" value:@[@"a", @"b"]];

                    id MockEntitlement = OCMClassMock([Entitlement class]);
                    OCMExpect([Entitlement compareProfileEntitlement:profile
                                                      appEntitlement:app
                                              isAssociatedDomainsKey:NO];).andReturn(
                                                                                     ProfileHasKeyExactly);

                    actual = [Entitlement compareAssociatedDomains:profile
                                                    appEntitlement:app];

                    expect(actual).to.equal(ProfileHasKeyExactly);

                    OCMVerifyAll(MockEntitlement);
                });
            });

            context(@"app value is a string", ^{
                it(@"returns ProfileDoesNotHaveRequiredKey if app value is '*'", ^{
                    profile = [Entitlement entitlementWithKey:@"key"
                                                        value:@[@"a", @"b"]];
                    app = [Entitlement entitlementWithKey:@"key" value:@"*"];
                    actual = [Entitlement compareAssociatedDomains:profile
                                                    appEntitlement:app];

                    expect(actual).to.equal(ProfileDoesNotHaveRequiredKey);
                });

                it(@"returns ProfileHasKey if app value is not '*'", ^{
                    profile = [Entitlement entitlementWithKey:@"key"
                                                        value:@[@"a", @"b"]];
                    app = [Entitlement entitlementWithKey:@"key" value:@"!*"];
                    actual = [Entitlement compareAssociatedDomains:profile
                                                    appEntitlement:app];

                    expect(actual).to.equal(ProfileHasKey);
                });
            });
        });

        context(@"profile has string value", ^{
            context(@"app has an array value", ^{
                it(@"returns ProfileDoesNotHaveRequiredKey if profile value is != '*'", ^{
                    profile = [Entitlement entitlementWithKey:@"key"
                                                        value:@"!*"];
                    app = [Entitlement entitlementWithKey:@"key"
                                                    value:@[@"a", @"b"]];
                    actual = [Entitlement compareAssociatedDomains:profile
                                                    appEntitlement:app];

                    expect(actual).to.equal(ProfileDoesNotHaveRequiredKey);
                });

                it(@"returns ProfileHasKeyExactly if profile value is '*'", ^{
                    profile = [Entitlement entitlementWithKey:@"key"
                                                        value:@"*"];
                    app = [Entitlement entitlementWithKey:@"key"
                                                    value:@[@"a", @"b"]];
                    actual = [Entitlement compareAssociatedDomains:profile
                                                    appEntitlement:app];

                    expect(actual).to.equal(ProfileHasKey);
                });
            });

            context(@"app has a string value", ^{
                it(@"returns ProfileHasKeyExactly if profile value matches app value", ^{
                    profile = [Entitlement entitlementWithKey:@"key"
                                                        value:@"value"];
                    app = [Entitlement entitlementWithKey:@"key"
                                                    value:@"value"];
                    actual = [Entitlement compareAssociatedDomains:profile
                                                    appEntitlement:app];

                    expect(actual).to.equal(ProfileHasKeyExactly);
                });

                it(@"returns ProfileHasKey if profile value is a non-matching string", ^{
                    profile = [Entitlement entitlementWithKey:@"key"
                                                        value:@"a"];
                    app = [Entitlement entitlementWithKey:@"key"
                                                    value:@"b"];
                    actual = [Entitlement compareAssociatedDomains:profile
                                                    appEntitlement:app];

                    expect(actual).to.equal(ProfileHasKey);
                });
            });
        });
    });
});
SpecEnd

