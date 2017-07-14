
#import "TestCase.h"
#import "Codesigner.h"
#import "CodesignResources.h"
#import "CLI.h"
#import "AppUtils.h"
#import "PhysicalDevice.h"
#import "Device.h"

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

- (void)testResignWithWildCardProfile {
    NSString *profilePath = [[Resources shared] CalabashWildcardPath];
    NSString *ipaPath = [[Resources shared] TaskyIpaPath];
    NSString *bundleID = [[Resources shared] TaskyIdentifier];
    NSString *outputPath = [[self.resources resourcesDirectory] stringByAppendingPathComponent:@"resigned-tasky.ipa"];
    NSArray *args = @[
                      kProgramName, @"resign",
                      ipaPath,
                      profilePath,
                      @"-o", outputPath
                      ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    NSString *calabashDylibPath = [CodesignResources CalabashDylibPath];
    MobileProfile *profile = [MobileProfile withPath:profilePath];
    CodesignIdentity *codesignID = [profile findValidIdentity];
    args = @[
             kProgramName, @"resign-object",
             calabashDylibPath,
             [codesignID shasum]
             ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"is-installed",
                          bundleID,
                          @"-d", defaultDeviceUDID
                          ];
        
        if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
            args = @[
                     kProgramName, @"uninstall",
                     bundleID,
                     @"-d", defaultDeviceUDID,
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }
        
        args = @[
                 kProgramName, @"install",
                 outputPath,
                 @"-d", defaultDeviceUDID,
                 @"-p", profilePath,
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        
        args = @[
                 kProgramName, @"launch-app",
                 bundleID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testResignWithSameIdentity {
    NSString *profilePath = [CodesignResources CalabashPermissionsProfilePath];
    NSString *ipaPath = [CodesignResources PermissionsIpaPath];
    NSString *bundleID = [CodesignResources PermissionsAppBundleID];
    NSString *outputPath = [[self.resources resourcesDirectory] stringByAppendingPathComponent:@"resigned-permissions.ipa"];
    NSArray *args;

    args = @[
             kProgramName, @"resign",
             ipaPath,
             profilePath,
             @"-o", outputPath
             ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);

    if (device_available()) {
        args = @[
                 kProgramName, @"is-installed",
                 bundleID,
                 @"-d", defaultDeviceUDID
                 ];

        if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
            args = @[
                     kProgramName, @"uninstall",
                     bundleID,
                     @"-d", defaultDeviceUDID
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }
        
        args = @[
                 kProgramName, @"install",
                 outputPath,
                 @"-d", defaultDeviceUDID,
                 @"-p", profilePath
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        
        args = @[
                 kProgramName, @"launch-app",
                 bundleID,
                 @"-d", defaultDeviceUDID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testResignWithDifferentProfile {
    if (!device_available()) { return; }

    NSString *profilePath = [self.resources pathToLJSProvisioningProfile];
    MobileProfile *profile = [MobileProfile withPath:profilePath];

    NSString *bundlePath = [AppUtils unzipToTmpDir:[CodesignResources PermissionsIpaPath]];
    Application *application = [Application withBundlePath:bundlePath];
    [Codesigner resignApplication:application withProvisioningProfile:profile];

    PhysicalDevice *device = [PhysicalDevice withID:defaultDeviceUDID];
    FBiOSDeviceOperator *operator = [device fbDeviceOperator];

    NSError *error = nil;
    iOSReturnStatusCode code = iOSReturnStatusCodeGenericFailure;
    BOOL success = NO;

    success = [device installProvisioningProfileAtPath:profile.path error:&error];
    expect(success).to.equal(YES);

    if ([device isInstalled:[application bundleID] withError:&error]) {
        code = [device uninstallApp:[application bundleID]];
        expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
    }

    BOOL actual = [operator installApplicationWithPath:[application path] error:&error];
    expect(actual).to.equal(YES);

    code = [device launchApp:[application bundleID]];
    expect(code).to.equal(iOSReturnStatusCodeEverythingOkay);
}

- (void)testResignAll {
//TODO
}

@end
