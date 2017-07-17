
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
    FBiOSDeviceOperator *operator = [device fbDeviceOperator];

    NSError *error = nil;
    iOSReturnStatusCode code = iOSReturnStatusCodeGenericFailure;
    BOOL success = NO;

    success = [device installProvisioningProfileAtPath:profile.path error:&error];
    expect(success).to.equal(YES);

    if ([device isInstalled:[app bundleID] withError:&error]) {
        code = [device uninstallApp:[app bundleID]];
        expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    BOOL actual = [operator installApplicationWithPath:[app path] error:&error];
    expect(actual).to.equal(YES);

    code = [device launchApp:[app bundleID]];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
}

- (void)testResignObjectWithIdentity {
    CodesignIdentity *karlIdentity = [self.resources KarlKrukowIdentityIOS];
    CodesignIdentity *moodyIdentity = [self.resources JoshuaMoodyIdentityIOS];

    NSString *target = [[self.resources uniqueTmpDirectory]
                        stringByAppendingPathComponent:@"signed.dylib"];
    NSString *source = [self.resources CalabashDylibPath];
    ShellResult *result;

    result = [ShellRunner xcrun:@[@"codesign", @"-vvv", @"--display", source]
                        timeout:5];
    expect([result.stderrStr containsString:karlIdentity.name]).to.beTruthy();

    NSFileManager *manager = [NSFileManager defaultManager];
    expect([manager copyItemAtPath:source toPath:target error:nil]).to.beTruthy();

    [Codesigner resignObject:target codesignIdentity:moodyIdentity];

    result = [ShellRunner xcrun:@[@"codesign", @"-vvv", @"--display", target]
                        timeout:5];
    expect([result.stderrStr containsString:moodyIdentity.name]).to.beTruthy();
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

    NSString *profilePath = [self.resources pathToLJSProvisioningProfile];
    MobileProfile *profile = [MobileProfile withPath:profilePath];

    [Codesigner resignApplication:app withProvisioningProfile:profile];

    NSDictionary *after = [Entitlements dictionaryOfEntitlementsWithBundlePath:app.path];
    expect(after[@"application-identifier"]).to.equal(@"Y54WEA9F74.*");

    [self expectApplicationToInstallAndLaunch:app
                                      profile:profile];
}

@end
