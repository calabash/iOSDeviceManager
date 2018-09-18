
#import "TestCase.h"
#import "XCTestConfigurationPlist.h"

@interface XCTestConfigurationPlist (TEST)

@end

@interface XCTestConfigurationPlistTest : TestCase

@end

@implementation XCTestConfigurationPlistTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testGenerateConfigBySubstitutingValues {

    NSString *xctestPath = @"/private/path/to/My.xctest";
    NSString *autInstalledPath = @"/private/path/to/AUT.app";
    NSString *autIdentifier = @"com.example.AUT";
    NSString *runnerInstalledPath = @"/private/path/to/AUT-Runner.app";
    NSString *runnerIdentifier = @"com.apple.test.AUT-Runner";
    NSString *sessionIdentifier = @"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";
    NSString *encodedSessionIdentifier = @"qqqqqru7zMzd3e7u7u7u7g==";

    NSString *actual = [XCTestConfigurationPlist plistWithXCTestInstallPath:xctestPath
                                                                AUTHostPath:autInstalledPath
                                                        AUTBundleIdentifier:autIdentifier
                                                             runnerHostPath:runnerInstalledPath
                                                     runnerBundleIdentifier:runnerIdentifier
                                                          sessionIdentifier:sessionIdentifier];

    expect([actual containsString:[NSString stringWithFormat:@"file://%@", xctestPath]]).to.equal(YES);
    expect([actual containsString:@"TEST_BUNDLE_URL"]).to.equal(NO);

    expect([actual containsString:autInstalledPath]).to.equal(YES);
    expect([actual containsString:@"AUT_INSTALLED_PATH"]).to.equal(NO);

    expect([actual containsString:autIdentifier]).to.equal(YES);
    expect([actual containsString:@"AUT_BUNDLE_IDENTIFIER"]).to.equal(NO);

    expect([actual containsString:runnerInstalledPath]).to.equal(YES);
    expect([actual containsString:@"RUNNER_INSTALLED_PATH"]).to.equal(NO);

    expect([actual containsString:runnerIdentifier]).to.equal(YES);
    expect([actual containsString:@"RUNNER_BUNDLE_IDENTIFIER"]).to.equal(NO);

    expect([actual containsString:encodedSessionIdentifier]).to.equal(YES);
    expect([actual containsString:@"SESSION_IDENTIFIER"]).to.equal(NO);

    expect([actual containsString:@"<string>AUT</string>"]).to.equal(YES);
    expect([actual containsString:@"RUNNER_TARGET_NAME"]).to.equal(NO);
}

@end
