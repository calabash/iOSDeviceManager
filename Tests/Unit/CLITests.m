#import "TestCase.h"
#import "CLI.h"
#import "DeviceUtils.h"

@interface CLI (priv)
@end

@implementation CLI (priv)
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
    NSArray *args = @[kProgramName, @"uninstall", @"bundle-id", @"-z", @"-d", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeUnrecognizedFlag);
}

- (void)testMissingArg {
    NSArray *args = @[kProgramName, @"uninstall", @"-d", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);

    args = @[kProgramName, @"install", @"fake/path/to/.app", @"-d"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);

    args = @[kProgramName, @"resign", @"-a", @"fake/path/to/.app"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);

    args = @[kProgramName, @"resign-object", @"/fake/path/to/.dylib"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);

    args = @[kProgramName, @"resign-all", @"fake/path/to/.app"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

- (void)testPositionalProfilePath {
    // Using invalid mobile provision profile
    NSArray *args = @[kProgramName, @"resign-all", @"fake/path/to/.app",
                      @"fake/path/to/profile.mobileprovision", @"-o", @"output-path"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInvalidArguments);
}

- (void)testPositionalFrameworkOrDylib {
    NSArray *args = @[kProgramName, @"resign-object", @"fake/path/to/.framework", @"-"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInternalError);

    args = @[kProgramName, @"resign-object", @"fake/path/to/.dylib", @"-"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeInternalError);
}

- (void)testMissingRequiredOption {
    NSArray *args = @[kProgramName, @"install", @"-d", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

@end
