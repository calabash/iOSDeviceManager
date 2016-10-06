
#import "TestCase.h"
#import "CLI.h"

@interface CLI (priv)
+ (NSString *)pathToCLIJSON;
@end

@implementation CLI (priv)
+ (NSString *)pathToCLIJSON {
    return [[[Resources shared] resourcesDirectory] stringByAppendingPathComponent:@"CLI.json"];
}
@end

@interface CLITests : TestCase

@end

@implementation CLITests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testNoArgs {
    XCTAssertEqual([CLI process:@[]], iOSReturnStatusCodeEverythingOkay);
}

- (void)testInvalidCommandName {
    NSArray *args = @[@"foooooozeball"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeUnrecognizedCommand);
}

- (void)testNoArguments {
    NSArray *args = @[@"uninstall"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

- (void)testInvalidFlag {
    NSArray *args = @[@"uninstall", @"-z"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeUnrecognizedFlag);
}

- (void)testMissingArg {
    NSArray *args = @[@"uninstall", @"-b"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);

    args = @[@"install", @"-a", @"fake/path/to/.app", @"-d"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

- (void)testMissingRequiredOption {
    NSArray *args = @[@"install", @"-a", @"fake/path/to/.app"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

@end
