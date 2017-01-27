
#import "TestCase.h"
#import "Codesigner.h"
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
    NSString *profilePath = [self.resources CalabashWildcardPath];
    NSString *ipaPath = [self.resources TaskyIpaPath];
    NSString *outputPath = [[self.resources resourcesDirectory] stringByAppendingPathComponent:@"resigned-tasky.ipa"];
    NSArray *args = @[
                      kProgramName, @"resign",
                      ipaPath,
                      @"-p", profilePath,
                      @"-o", outputPath
                      ];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testResignWithSameIdentity {
    // TODO
}

- (void)testResignWithDifferentIdentity {
    //TODO
}

@end
