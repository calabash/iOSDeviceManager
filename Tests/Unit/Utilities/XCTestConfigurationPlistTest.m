
#import "TestCase.h"
#import "XCTestConfigurationPlist.h"

@interface XCTestConfigurationPlist (TEST)

+ (NSString *)plistWithXCTestInstallPath:(NSString *)testInstallPath
                        AUTInstalledPath:(NSString *)autInstallPath
                     AUTBundleIdentifier:(NSString *)autBundleIdentifier
                     runnerInstalledPath:(NSString *)runnerInstallPath
                  runnerBundleIdentifier:(NSString *)runnerBundleIdentifier
                       sessionIdentifier:(NSString *)UUID;

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
    NSString *sessionIdentifier = @"BE5BA3D0-971C-4418-9ECF-E2D1ABCB66BE";
    NSString *encodedSessionIdentifier = @"QkU1QkEzRDAtOTcxQy00NDE4LTlFQ0YtRTJEMUFCQ0I2NkJF";

    NSString *actual = [XCTestConfigurationPlist plistWithXCTestInstallPath:xctestPath
                                                           AUTInstalledPath:autInstalledPath
                                                        AUTBundleIdentifier:autIdentifier
                                                        runnerInstalledPath:runnerInstalledPath
                                                     runnerBundleIdentifier:runnerIdentifier
                                                          sessionIdentifier:sessionIdentifier];

    expect([actual containsString:[xctestPath stringByAppendingString:@"file://"]]).to.equal(YES);
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
}

@end
