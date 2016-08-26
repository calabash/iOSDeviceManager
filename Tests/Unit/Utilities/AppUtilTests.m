
#import "TestCase.h"
#import "AppUtils.h"

@interface AppUtilTests : TestCase

@end

@implementation AppUtilTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testAppVersionDifferent {
    NSDictionary *plist1 = @{};
    NSDictionary *plist2 = @{};

    XCTAssertThrows([AppUtils appVersionIsDifferent:plist1 newPlist:plist2],
                    @"Invalid plists shouldn't be accepted");

    plist1 = @{@"CFBundleShortVersionString" : @"1",
               @"CFBundleVersion" : @"1"};

    plist2 = @{@"CFBundleShortVersionString" : @"1",
               @"CFBundleVersion" : @"1"};

    XCTAssertFalse([AppUtils appVersionIsDifferent:plist1 newPlist:plist2]);

    plist1 = @{@"CFBundleShortVersionString" : @"1",
               @"CFBundleVersion" : @"1"};

    plist2 = @{@"CFBundleShortVersionString" : @"2",
               @"CFBundleVersion" : @"1"};

    XCTAssertTrue([AppUtils appVersionIsDifferent:plist1 newPlist:plist2]);

    plist1 = @{@"CFBundleShortVersionString" : @"1",
               @"CFBundleVersion" : @"2"};

    plist2 = @{@"CFBundleShortVersionString" : @"1",
               @"CFBundleVersion" : @"1"};

    XCTAssertTrue([AppUtils appVersionIsDifferent:plist1 newPlist:plist2]);

    plist1 = @{@"CFBundleShortVersionString" : @"2",
               @"CFBundleVersion" : @"2"};

    plist2 = @{@"CFBundleShortVersionString" : @"1",
               @"CFBundleVersion" : @"1"};

    XCTAssertTrue([AppUtils appVersionIsDifferent:plist1 newPlist:plist2]);
}

@end
