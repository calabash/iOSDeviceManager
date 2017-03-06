
#import "TestCase.h"
#import "Codesigner.h"
#import "CodesignResources.h"
#import "CLI.h"

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
                      @"-p", profilePath,
                      @"-o", outputPath
                      ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    NSString *calabashDylibPath = [CodesignResources CalabashDylibPath];
    MobileProfile *profile = [MobileProfile withPath:profilePath];
    CodesignIdentity *codesignID = [profile findValidIdentity];
    args = @[
             kProgramName, @"resign_object",
             calabashDylibPath,
             @"-c", [codesignID shasum]
             ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"is_installed",
                          @"-b", bundleID,
                          @"-d", defaultDeviceUDID
                          ];
        
        if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
            args = @[
                     kProgramName, @"uninstall",
                     @"-d", defaultDeviceUDID,
                     @"-b", bundleID
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }
        
        args = @[
                 kProgramName, @"install",
                 @"-d", defaultDeviceUDID,
                 @"-p", profilePath,
                 @"-a", outputPath
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        
        args = @[
                 kProgramName, @"launch_app",
                 @"-d", defaultDeviceUDID,
                 @"-b", bundleID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testResignWithSameIdentity {
    NSString *profilePath = [CodesignResources CalabashPermissionsProfilePath];
    NSString *ipaPath = [CodesignResources PermissionsIpaPath];
    NSString *bundleID = [CodesignResources PermissionsAppBundleID];
    NSString *outputPath = [[self.resources resourcesDirectory] stringByAppendingPathComponent:@"resigned-permissions.ipa"];
    NSArray *args = @[
                      kProgramName, @"resign",
                      ipaPath,
                      @"-p", profilePath,
                      @"-o", outputPath
                      ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    if (device_available()) {
        NSArray *args = @[
                          kProgramName, @"is_installed",
                          @"-b", bundleID,
                          @"-d", defaultDeviceUDID
                          ];
        
        if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
            args = @[
                     kProgramName, @"uninstall",
                     @"-d", defaultDeviceUDID,
                     @"-b", bundleID
                     ];
            XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        }
        
        args = @[
                 kProgramName, @"install",
                 @"-d", defaultDeviceUDID,
                 @"-p", profilePath,
                 @"-a", outputPath
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
        
        args = @[
                 kProgramName, @"launch_app",
                 @"-d", defaultDeviceUDID,
                 @"-b", bundleID
                 ];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
}

- (void)testResignWithDifferentIdentity {
//TODO
}

- (void)testResignAll {
//TODO
}

@end
