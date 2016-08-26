
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
    XCTAssertEqual([CLI process:@[kProgramName]], iOSReturnStatusCodeEverythingOkay);
}

- (void)testInvalidCommandName {
    NSArray *args = @[kProgramName, @"foooooozeball"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeUnrecognizedCommand);
}

- (void)testNoArguments {
    NSArray *args = @[kProgramName, @"uninstall"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

- (void)testInvalidFlag {
    NSArray *args = @[kProgramName, @"uninstall", @"-z"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeUnrecognizedFlag);
}

- (void)testMissingArg {
    NSArray *args = @[kProgramName, @"uninstall", @"-b"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);

    args = @[kProgramName, @"install", @"-a", @"fake/path/to/.app", @"-d"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

- (void)testMissingRequiredOption {
    NSArray *args = @[kProgramName, @"install", @"-a", @"fake/path/to/.app"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

@end
