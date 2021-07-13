
#import "TestCase.h"
#import "Codesigner.h"
#import "CLI.h"
#import "AppUtils.h"
#import "PhysicalDevice.h"
#import "Device.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "Entitlements.h"

@interface PhysicalDevice (TEST)

- (FBDevice *)fbDevice;
- (BOOL)installProvisioningProfileAtPath:(NSString *)path
                                   error:(NSError **)error;

@end

@interface ResignTest : TestCase

@end

@implementation ResignTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)expectApplicationToInstallAndLaunch:(Application *)app
                                    profile:(MobileProfile *)profile {

    if (!device_available()) { return; }

    PhysicalDevice *device = [PhysicalDevice withID:defaultDeviceUDID];

    NSError *error = nil;
    iOSReturnStatusCode code = iOSReturnStatusCodeGenericFailure;
    BOOL success = NO;

    success = [device installProvisioningProfileAtPath:profile.path error:&error];
    expect(success).to.equal(YES);

    if ([device isInstalled:[app bundleID] withError:&error]) {
        code = [device uninstallApp:[app bundleID]];
        expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    BOOL actual = [[device.fbDevice installApplicationWithPath:app.path] await:&error] != nil;
    expect(actual).to.equal(YES);

    code = [device launchApp:[app bundleID]];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);

    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 5.0, false);

    code = [device uninstallApp:[app bundleID]];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
}

- (void)testResignObjectWithIdentity {
    CodesignIdentity *iOSIdentity = [self.resources KarlKrukowIdentityIOS];
    CodesignIdentity *combinedIdentity = [self.resources KarlKrukowIdentityCombined];

    NSString *target = [[self.resources uniqueTmpDirectory]
                        stringByAppendingPathComponent:@"signed.dylib"];
    NSString *source = [self.resources CalabashDylibPath];
    ShellResult *result;

    result = [ShellRunner xcrun:@[@"codesign", @"-vvv", @"--display", source]
                        timeout:5];
    expect([result.stderrStr containsString:iOSIdentity.name]).to.beTruthy();

    NSFileManager *manager = [NSFileManager defaultManager];
    expect([manager copyItemAtPath:source toPath:target error:nil]).to.beTruthy();

    [Codesigner resignObject:target codesignIdentity:combinedIdentity];

    result = [ShellRunner xcrun:@[@"codesign", @"-vvv", @"--display", target]
                        timeout:5];
    expect([result.stderrStr containsString:combinedIdentity.name]).to.beTruthy();
}

- (void)testResignWithExactMatchProfile {
    NSString *bundlePath = [AppUtils unzipToTmpDir:[self.resources PermissionsIpaPath]];
    Application *app = [Application withBundlePath:bundlePath];

    NSDictionary *before = [Entitlements dictionaryOfEntitlementsWithBundlePath:app.path];
    expect(before[@"application-identifier"]).to.equal(@"FYD86LA7RE.sh.calaba.Permissions");

    MobileProfile *profile = [MobileProfile withPath:[self.resources PermissionsProfilePath]];
    [Codesigner resignApplication:app withProvisioningProfile:profile];

    NSDictionary *after = [Entitlements dictionaryOfEntitlementsWithBundlePath:app.path];
    expect(after[@"application-identifier"]).to.equal(@"FYD86LA7RE.sh.calaba.Permissions");

    [self expectApplicationToInstallAndLaunch:app
                                      profile:profile];
}

- (void)testResignWithWildcardProfileThatContainsForeignCertificate {
    NSString *bundlePath = [AppUtils unzipToTmpDir:[self.resources PermissionsIpaPath]];
    Application *app = [Application withBundlePath:bundlePath];

    NSDictionary *before = [Entitlements dictionaryOfEntitlementsWithBundlePath:app.path];
    expect(before[@"application-identifier"]).to.equal(@"FYD86LA7RE.sh.calaba.Permissions");

    // Cannot test with the CalabashWildcardProfile because the final application
    // identifier would be the same - the signing algorithm just replaces the
    // prefix (eg. FYD86LA7RE.* => FYD86LA7RE.com.example.App) of the app
    // identifier.
    //
    // Ideally, we would use a profile from different developer account, but
    // that is expensive and hard to maintain.
    NSString *profilePath = [self.resources PalisadeDevelopmentProfilePath];
    MobileProfile *profile = [MobileProfile withPath:profilePath];

    CodesignIdentity *combinedIdentity = [self.resources KarlKrukowIdentityCombined];

    // Ideally, we would not specify a code sign identity, but instead rely on
    // the algorithm to find a correct cert/profile/app triple.  This would
    // mean using a certificate from another developer account which would be
    // hard to maintain or creating special profile just for this test.
    [Codesigner resignApplication:app
          withProvisioningProfile:profile
             withCodesignIdentity:combinedIdentity];

    NSDictionary *after = [Entitlements dictionaryOfEntitlementsWithBundlePath:app.path];
    expect(after[@"application-identifier"]).to.equal(@"FYD86LA7RE.com.microsoft.Palisade");


    ShellResult *result;

    result = [ShellRunner xcrun:@[@"codesign", @"-vvv", @"--display", app.path]
                        timeout:5];
    expect([result.stderrStr containsString:combinedIdentity.name]).to.beTruthy();

    [self expectApplicationToInstallAndLaunch:app profile:profile];
}

@end
