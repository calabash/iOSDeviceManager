
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
    NSString *profilePath = [CodesignResources CalabashWildcardProfilePath];
    NSString *ipaPath = [self.resources TaskyIpaPath];
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
}

- (void)testResignWithSameIdentity {
    NSString *profilePath = [CodesignResources CalabashPermissionsProfilePath];
    NSString *ipaPath = [CodesignResources PermissionsIpaPath];
    NSString *outputPath = [[self.resources resourcesDirectory] stringByAppendingPathComponent:@"resigned-permissions.ipa"];
    NSArray *args = @[
                      kProgramName, @"resign",
                      ipaPath,
                      @"-p", profilePath,
                      @"-o", outputPath
                      ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testResignWithDifferentIdentity {
//TODO
}

- (void)testResignAll {
//TODO
}

@end
