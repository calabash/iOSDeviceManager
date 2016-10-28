
#import "TestCase.h"
#import "MobileProfile.h"
#import "ShellRunner.h"
#import "Certificate.h"
#import "Entitlements.h"

@interface MobileProfile ()

+ (NSString *)stringByExportingProfileWithSecurity:(NSString *)path;
+ (NSDictionary *)dictionaryByExportingProfileWithSecurity:(NSString *) path;
+ (NSString *)profilesDirectory;
+ (NSArray<NSString *> *)arrayOfProfilePaths;
- (id)objectForKeyedSubscript:(NSString *)key;
- (NSInteger)rank;
- (instancetype)initWithDictionary:(NSDictionary *)info
                              path:(NSString *)path;


@end

@interface MobileProfileTest : TestCase

@end

@implementation MobileProfileTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Class Methods

- (void)testMobileProvisionDirectory {
    NSString *path = [MobileProfile profilesDirectory];
    expect([self fileExists:path]).to.equal(YES);
}

- (void)testDictionaryFromProfile {
    NSString *path = [self.resources CalabashWildcardPath];
    NSDictionary *hash = [MobileProfile dictionaryByExportingProfileWithSecurity:path];
    expect(hash.count).notTo.equal(0);
    expect(hash[@"AppIDName"]).to.equal(@"CalabashWildcard");
}

- (void)testHasMethodsForReturningProfileDetails {
    NSString *path = [self.resources CalabashWildcardPath];
    NSDictionary *hash = [MobileProfile dictionaryByExportingProfileWithSecurity:path];
    MobileProfile *profile = [[MobileProfile alloc] initWithDictionary:hash
                                                                  path:path];
    expect(profile.AppIDName).to.equal(@"CalabashWildcard");
    expect(profile.ApplicationIdentifierPrefix[0]).to.equal(@"FYD86LA7RE");
    expect(profile.DeveloperCertificates.count).to.equal(1);
    expect(profile.DeveloperCertificates[0]).to.beInstanceOf([Certificate class]);
    expect(profile.ProvisionedDevices.count).to.equal(26);
    expect(profile.ProvisionedDevices[0]).to.equal(@"e60ef9ae876ab4a218ee966d0525c9fb79e5606d");
    expect(profile.TeamIdentifier[0]).to.equal(@"FYD86LA7RE");
    expect(profile.UUID).to.equal(@"49fc8ecd-d772-432c-adc3-25e7db53b847");
    expect(profile.TeamName).to.equal(@"Karl Krukow");
    expect(profile.Name).to.equal(@"CalabashWildcard");
    expect(profile.Platform[0]).to.equal(@"iOS");
    expect(profile.ExpirationDate).to.beInstanceOf(NSClassFromString(@"__NSTaggedDate"));

    NSLog(@"%@", profile.info);

    Certificate *cert = profile.DeveloperCertificates[0];
    expect(cert.userID).to.equal(@"QWAW7NSN85");
    expect(cert.commonName).to.equal(@"iPhone Developer: Karl Krukow (YTTN6Y2QS9)");
    expect(cert.teamName).to.equal(@"FYD86LA7RE");
    expect(cert.organization).to.equal(@"Karl Krukow");
    expect(cert.country).to.equal(@"US");

    Entitlements *entitlements = profile.Entitlements;
    expect(entitlements[@"get-task-allow"]).to.equal(@(1));
    NSLog(@"%@", entitlements);

    NSLog(@"%@", [path pathExtension]);
}

- (void)testCanImportProblematicProfiles {
    NSString *path = [self.resources pathToVeryLongProfile];
    NSDictionary *hash = [MobileProfile dictionaryByExportingProfileWithSecurity:path];
    MobileProfile *profile = [[MobileProfile alloc] initWithDictionary:hash
                                                                  path:path];
    expect(profile.AppIDName).to.equal(@"Xcode iOS App ID app group xam app-cal");
    expect(profile.ApplicationIdentifierPrefix[0]).to.equal(@"58LM7J37Q8");
    expect(profile.DeveloperCertificates.count).to.equal(33);
    expect(profile.DeveloperCertificates[0]).to.beInstanceOf([Certificate class]);
    expect(profile.ProvisionedDevices.count).to.equal(83);
    expect(profile.ProvisionedDevices[0]).to.equal(@"f90928195b6e6709405c608f03e0a425b0e4cd10");
    expect(profile.TeamIdentifier[0]).to.equal(@"58LM7J37Q8");
    expect(profile.UUID).to.equal(@"64fb01e1-61ed-4bcf-b4fe-16221f047f84");
    expect(profile.TeamName).to.equal(@"Xamarin Inc");
    expect(profile.Name).to.equal(@"iOS Team Provisioning Profile: app.group.xam.app-cal");
    expect(profile.Platform[0]).to.equal(@"iOS");
    expect(profile.ExpirationDate).to.beInstanceOf(NSClassFromString(@"__NSTaggedDate"));

    NSLog(@"%@", profile.info);

    Certificate *cert = profile.DeveloperCertificates[0];
    expect(cert.userID).to.equal(@"3TNVSMTY3X");
    expect(cert.commonName).to.equal(@"iPhone Developer: Andrew Chung (28DXNYAUL2)");
    expect(cert.teamName).to.equal(@"58LM7J37Q8");
    expect(cert.organization).to.equal(@"Xamarin Inc");
    expect(cert.country).to.equal(@"US");

    Entitlements *entitlements = profile.Entitlements;
    expect(entitlements[@"get-task-allow"]).to.equal(@(1));
    NSLog(@"%@", entitlements);
}

- (void)testCanImportLJSProfile {
    NSString *path = [self.resources pathToVeryLongProfile];
    NSDictionary *hash = [MobileProfile dictionaryByExportingProfileWithSecurity:path];
    MobileProfile *profile = [[MobileProfile alloc] initWithDictionary:hash
                                                                  path:path];

    NSLog(@"profile = %@", profile);
}


// Could be an integration test if import is too slow.
- (void)testCanImportMyProfiles {
    NSArray<MobileProfile *> *profiles;
    profiles = [MobileProfile nonExpiredIOSProfiles];
    expect(profiles).notTo.equal(nil);
    expect(profiles.count).notTo.equal(0);
}

@end

SpecBegin(MobileProfile)


context(@"Instance Methods", ^{
    __block MobileProfile *profile;

    before(^{
        profile = [[MobileProfile alloc]
                   initWithDictionary:@{@"KEY": @"VALUE"}
                   path:@"path/to/profile"];
    });

    context(@"#initWithDictionary:path:", ^{
        it(@"returns an instance with _info and _path set", ^{
            NSString *path = @"path/to/profile";
            NSDictionary *info = @{@"KEY": @"VALUE"};
            profile = [[MobileProfile alloc]
                       initWithDictionary:@{@"KEY": @"VALUE"}
                       path:@"path/to/profile"];

            expect(profile.info).to.equal(info);
            expect(profile.path).to.equal(path);
            expect(profile.rank).to.equal(0);
        });
    });

    context(@"#objectForKeyedSubscript:", ^{
        it(@"returns the value for key in info dictionary", ^{
            expect(profile[@"KEY"]).to.equal(@"VALUE");
        });

        it(@"returns the value for key in info dictionary", ^{
            expect(profile[@"OTHER"]).to.equal(nil);
        });
    });

    context(@"#isPlatformIOS", ^{
        __block id mock;
        __block NSArray<NSString *> *platforms;

        before(^{
            mock = OCMPartialMock(profile);
        });

        after(^{
            OCMVerifyAll(mock);
        });

        it(@"returns true if platform contains iOS", ^{
            platforms = @[@"iOS", @"watchOS"];
            OCMExpect([mock Platform]).andReturn(platforms);

            expect(profile.isPlatformIOS).to.equal(YES);
        });

        it(@"returns false if platform does not contain iOS", ^{
            platforms = @[@"watchOS"];
            OCMExpect([mock Platform]).andReturn(platforms);

            expect(profile.isPlatformIOS).to.equal(NO);
        });
    });

    context(@"#isExpired", ^{
        __block id mock;
        __block NSDate *date;

        before(^{
            mock = OCMPartialMock(profile);
        });

        after(^{
            OCMVerifyAll(mock);
        });

        it(@"returns true if profile has expired", ^{
            date = [NSDate distantPast];
            OCMExpect([mock ExpirationDate]).andReturn(date);

            expect(profile.isExpired).to.equal(YES);
        });

        it(@"returns false if profile has not expired", ^{
            date = [NSDate distantFuture];
            OCMExpect([mock ExpirationDate]).andReturn(date);

            expect(profile.isExpired).to.equal(NO);
        });
    });

    context(@"#containsDeviceUDID:", ^{
        __block id mock;
        __block NSString *udid = @"<UDID>";

        before(^{
            mock = OCMPartialMock(profile);
        });

        after(^{
            OCMVerifyAll(mock);
        });

        it(@"returns true if the device is in this profile", ^{
            OCMExpect([mock ProvisionedDevices]).andReturn(@[@"<UDID>"]);

            expect([profile containsDeviceUDID:udid]).to.equal(YES);
        });

        it(@"returns false if the device is not in this profile", ^{
            OCMExpect([mock ProvisionedDevices]).andReturn(@[]);

            expect([profile containsDeviceUDID:udid]).to.equal(NO);
        });
    });
});

#pragma mark - Class Method Examples

context(@".arrayOfProfilePaths:", ^{
    __block id MockMobileProfile;
    __block NSArray<NSString *> *actual;
    __block NSString *directory;

    before(^{
        MockMobileProfile = OCMClassMock([MobileProfile class]);
    });

    after(^{
        OCMVerifyAll(MockMobileProfile);
    });

    it(@"returns an array of paths to profiles from the user's Library", ^{
        directory = [[Resources shared] provisioningProfilesDirectory];
        OCMExpect([MockMobileProfile profilesDirectory]).andReturn(directory);

        actual = [MobileProfile arrayOfProfilePaths];
        expect(actual.count).to.equal(8);
        expect([[NSFileManager defaultManager]
                fileExistsAtPath:actual[0]]).to.equal(YES);
    });

    it(@"returns nil if there is an error getting the contents of the directory", ^{
        directory = @"path/to/some/directory";
        OCMExpect([MockMobileProfile profilesDirectory]).andReturn(directory);

        actual = [MobileProfile arrayOfProfilePaths];
        expect(actual).to.equal(nil);
    });

    it(@"returns nil if no profiles are found", ^{
        directory = [[Resources shared] tmpDirectoryWithName:@"Provisioning Profiles"];
        OCMExpect([MockMobileProfile profilesDirectory]).andReturn(directory);

        actual = [MobileProfile arrayOfProfilePaths];
        expect(actual).to.equal(nil);
    });
});

context(@".stringByExportingProfileWithSecurity:", ^{
    __block id MockShellRunner;
    __block ShellResult *shellResult;

    before(^{
        MockShellRunner = OCMClassMock([ShellRunner class]);
    });

    after(^{
        OCMVerifyAll(MockShellRunner);
    });

    it(@"returns nil if security cannot export the profile", ^{
        shellResult = [[Resources shared] failedResult];
        OCMExpect([MockShellRunner xcrun:OCMOCK_ANY timeout:10]).andReturn(shellResult);

        NSString *actual = [MobileProfile stringByExportingProfileWithSecurity:@""];
        expect(actual).to.equal(nil);
    });
});

context(@".dictionaryByExportingProfileWithSecurity:", ^{
    __block id MockMobileProfile;
    __block NSString *path;
    __block NSString *plist;
    __block NSDictionary *actual;

    before(^{
        MockMobileProfile = OCMClassMock([MobileProfile class]);
        path = @"path/to/my.mobileprovision";
        plist = [[Resources shared] stringPlist];
    });

    after(^{
        OCMVerifyAll(MockMobileProfile);
    });

    it(@"returns an NSDictionary representation of a profile", ^{
        OCMExpect([MockMobileProfile
                   stringByExportingProfileWithSecurity:path]).andReturn(plist);

        actual = [MobileProfile dictionaryByExportingProfileWithSecurity:path];
        expect(actual.count).to.equal(1);
        expect(actual[@"KEY"]).to.equal(@"VALUE");
    });

    it(@"returns nil if security could not convert profile to a string", ^{
        OCMExpect([MockMobileProfile
                   stringByExportingProfileWithSecurity:path]).andReturn(nil);

        actual = [MobileProfile dictionaryByExportingProfileWithSecurity:path];
        expect(actual).to.equal(nil);
    });

    it(@"returns nil if plist could not be converted to a dictionary", ^{
        OCMExpect([MockMobileProfile
                   stringByExportingProfileWithSecurity:path]).andReturn(@"");

        actual = [MobileProfile dictionaryByExportingProfileWithSecurity:path];
        expect(actual).to.equal(nil);
    });
});

context(@"embeddedMobileProvision:identity:deviceUDID:", ^{

    __block NSString *bundlePath;
    __block NSString *provisionPath;
    __block CodesignIdentity *identity;
    // denis - Joshua Moody's iPhone 6 Plus - it is in the profile!
    __block NSString *UDID = @"193688959205dc7eb48d603c558ede919ad8dd0d";
    __block id MockMobileProfile;
    __block MobileProfile *embedded;

    before(^{
        bundlePath = testApp(ARM);
        provisionPath = [bundlePath stringByAppendingPathComponent:@"embedded.mobileprovision"];
        identity = [[Resources shared] KarlKrukowIdentity];
        MockMobileProfile = OCMClassMock([MobileProfile class]);
        embedded = nil;
    });

    after(^{
        OCMVerifyAll(MockMobileProfile);
    });

    it(@"returns nil if there is no embedded.mobileprovision", ^{
        id mockManager = OCMPartialMock([NSFileManager defaultManager]);
        OCMExpect([mockManager fileExistsAtPath:provisionPath]).andReturn(NO);

        embedded = [MobileProfile embeddedMobileProvision:bundlePath
                                                 identity:identity
                                               deviceUDID:UDID];
        expect(embedded).to.beNil();

        OCMVerifyAll(mockManager);
        [mockManager stopMocking];
    });

    it(@"returns nil if the provision cannot be exported with security", ^{
        OCMExpect(
                  [MockMobileProfile dictionaryByExportingProfileWithSecurity:provisionPath]
                  ).andReturn(nil);

        embedded = [MobileProfile embeddedMobileProvision:bundlePath
                                                 identity:identity
                                               deviceUDID:UDID];
        expect(embedded).to.beNil();
    });

    it(@"returns nil if the profile is expired", ^{
        OCMExpect([MockMobileProfile alloc]).andReturn(MockMobileProfile);
        OCMExpect(
                  [MockMobileProfile initWithDictionary:OCMOCK_ANY
                                                   path:OCMOCK_ANY]
                  ).andReturn(MockMobileProfile);

        OCMExpect([MockMobileProfile isExpired]).andReturn(YES);

        embedded = [MobileProfile embeddedMobileProvision:bundlePath
                                                 identity:identity
                                               deviceUDID:UDID];
        expect(embedded).to.beNil();
    });

    it(@"returns nil if the profile does not contain the device UDID", ^{
        OCMExpect([MockMobileProfile alloc]).andReturn(MockMobileProfile);
        OCMExpect(
                  [MockMobileProfile initWithDictionary:OCMOCK_ANY
                                                   path:OCMOCK_ANY]
                  ).andReturn(MockMobileProfile);

        OCMExpect([MockMobileProfile isExpired]).andReturn(NO);
        OCMExpect([MockMobileProfile ProvisionedDevices]).andReturn(@[]);

        embedded = [MobileProfile embeddedMobileProvision:bundlePath
                                                 identity:identity
                                               deviceUDID:UDID];
        expect(embedded).to.beNil();
    });

    it(@"returns nil if the identity is not found in the profile certs", ^{
        OCMExpect([MockMobileProfile alloc]).andReturn(MockMobileProfile);
        OCMExpect(
                  [MockMobileProfile initWithDictionary:OCMOCK_ANY
                                                   path:OCMOCK_ANY]
                  ).andReturn(MockMobileProfile);

        OCMExpect([MockMobileProfile isExpired]).andReturn(NO);
        OCMExpect([MockMobileProfile ProvisionedDevices]).andReturn(@[UDID]);
        OCMExpect([MockMobileProfile DeveloperCertificates]).andReturn(@[]);

        embedded = [MobileProfile embeddedMobileProvision:bundlePath
                                                 identity:identity
                                               deviceUDID:UDID];
        expect(embedded).to.beNil();
    });

    it(@"returns a MobileProfile if the provision has the device and the cert", ^{
        embedded = [MobileProfile embeddedMobileProvision:bundlePath
                                                 identity:identity
                                               deviceUDID:UDID];
        expect(embedded).notTo.beNil();
    });
});

SpecEnd
