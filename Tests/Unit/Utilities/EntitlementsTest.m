
#import "TestCase.h"
#import "Entitlements.h"
#import "ShellRunner.h"

@interface Entitlements (TEST)

+ (NSDictionary *)dictionaryOfEntitlementsWithBundlePath:(NSString *)bundlePath;
- (NSDictionary *)dictionary;

@end

@interface EntitlementsTest : TestCase

@end

@implementation EntitlementsTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testEntitlementsFromBundlePath {
    NSString *path = testApp(ARM);
    NSDictionary *plist = [Entitlements dictionaryOfEntitlementsWithBundlePath:path];

    expect(plist.count).notTo.equal(0);
    expect(plist[@"application-identifier"]).to.equal(@"FYD86LA7RE.sh.calaba.TestApp");
    expect(plist[@"com.apple.developer.team-identifier"]).to.equal(@"FYD86LA7RE");
    expect(plist[@"get-task-allow"]).to.equal(@(YES));
    expect(plist[@"keychain-access-groups"]).to.equal(@[@"FYD86LA7RE.sh.calaba.TestApp"]);
}

- (void)testEntitlementsFromBundlePathCommandFailed {
    NSString *path = testApp(ARM);

    ShellResult *result = [[Resources shared] failedResult];
    id MockShellRunner = OCMClassMock([ShellRunner class]);
    OCMExpect([MockShellRunner xcrun:OCMOCK_ANY timeout:10]).andReturn(result);

    NSDictionary *plist = [Entitlements dictionaryOfEntitlementsWithBundlePath:path];
    expect(plist).to.equal(nil);

    OCMVerifyAll(MockShellRunner);
}

- (void)testEntitlementsFromBundlePathCommandTimedOut {
    NSString *path = testApp(ARM);

    ShellResult *result = [[Resources shared] timedOutResult];
    id MockShellRunner = OCMClassMock([ShellRunner class]);
    OCMExpect([MockShellRunner xcrun:OCMOCK_ANY timeout:10]).andReturn(result);

    NSDictionary *plist = [Entitlements dictionaryOfEntitlementsWithBundlePath:path];
    expect(plist).to.equal(nil);

    OCMVerifyAll(MockShellRunner);
}

- (void)testEntitlementsFromBundlePathCommandCannotCreatePlist {
    NSString *path = testApp(ARM);
    id MockSerializer = OCMClassMock([NSPropertyListSerialization class]);
    NSError *error;

    OCMExpect(
              [MockSerializer propertyListWithData:OCMOCK_ANY
                                           options:NSPropertyListImmutable
                                            format:nil
                                             error:[OCMArg setTo:error]]
              ).andReturn(nil);

    NSDictionary *plist = [Entitlements dictionaryOfEntitlementsWithBundlePath:path];
    expect(plist).to.equal(nil);

    OCMVerifyAll(MockSerializer);
}

- (void)testEntitlementsFromBundlePathCommandEmptyPlist {
    NSString *path = testApp(ARM);
    id MockSerializer = OCMClassMock([NSPropertyListSerialization class]);
    NSError *error;

    OCMExpect(
              [MockSerializer propertyListWithData:OCMOCK_ANY
                                           options:NSPropertyListImmutable
                                            format:nil
                                             error:[OCMArg setTo:error]]
              ).andReturn(@{});

    NSDictionary *plist = [Entitlements dictionaryOfEntitlementsWithBundlePath:path];
    expect(plist).to.equal(nil);

    OCMVerifyAll(MockSerializer);
}

- (void)testEntitlementsFromBundlePathSuccess {
    NSString *path = testApp(ARM);
    Entitlements *entitlements = [Entitlements entitlementsWithBundlePath:path];

    expect(entitlements).notTo.equal(nil);
    expect(entitlements.dictionary.count).notTo.equal(0);
    NSLog(@"%@", entitlements);
}

- (void)testEntitlementsFromBundlePathFailure {
    NSString *path = testApp(ARM);

    id MockEntitlements = OCMClassMock([Entitlements class]);
    OCMExpect(
              [MockEntitlements dictionaryOfEntitlementsWithBundlePath:path]
              ).andReturn(nil);

    Entitlements *entitlements = [Entitlements entitlementsWithBundlePath:path];

    expect(entitlements).to.equal(nil);
}

- (void)testEntitlementsWithDictionary {
    NSDictionary *dictionary = @{@"key" : @"value"};
    Entitlements *entitlements = [Entitlements entitlementsWithDictionary:dictionary];

    expect(entitlements.dictionary).to.equal(dictionary);
};

- (void)testRespondsToObjectForKey {
    Entitlements *entitlements = [[Resources shared] entitlements];
    expect(entitlements[@"get-task-allow"]).to.equal(YES);
}

- (void)testEntitlementsByReplacingApplicationIdentifier {
    Entitlements *original = [[Resources shared] entitlements];
    Entitlements *updated;

    expect(original[@"application-identifier"]).to.equal(@"FYD86LA7RE.sh.calaba.TestApp");

    NSString *newAppID = @"ABCD.com.example.Example";
    updated = [original entitlementsByReplacingApplicationIdentifier:newAppID];

    expect(updated[@"application-identifier"]).to.equal(newAppID);
}

@end

SpecBegin(Entitlements)

context(@"#writeToFile:", ^{
    __block Entitlements *entitlements;
    __block NSString *path;
    __block id mockDictionary;

    before(^{
        entitlements = [[Resources shared] entitlements];
        path = @"a/path/to/file";
        mockDictionary = OCMPartialMock([entitlements dictionary]);
    });

    after(^{
        OCMVerifyAll(mockDictionary);
        [mockDictionary stopMocking];
    });

    it(@"returns YES if the file was written successfully", ^{
        OCMExpect([mockDictionary writeToFile:path
                                   atomically:YES]).andReturn(YES);

        expect([entitlements writeToFile:path]).to.equal(YES);
    });

    it(@"returns NO if the file was not written successfully", ^{
        OCMExpect([mockDictionary writeToFile:path
                                   atomically:YES]).andReturn(NO);

        expect([entitlements writeToFile:path]).to.equal(NO);
    });
});

SpecEnd
