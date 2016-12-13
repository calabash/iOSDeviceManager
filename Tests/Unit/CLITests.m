
#import "TestCase.h"
#import "CLI.h"

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
    NSArray *args = @[kProgramName, @"uninstall", @"-z"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeUnrecognizedFlag);
}

- (void)testPositionalArgument {
    NSArray *args = @[kProgramName, @"uninstall", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE", @"-b", @"bundle_id"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeDeviceNotFound);
    
    args = @[kProgramName, @"install", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE", @"-a", @"path/to/app/bundle"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeDeviceNotFound);
    
    args = @[kProgramName, @"launch_simulator", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeDeviceNotFound);
    
    args = @[kProgramName, @"kill_simulator", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeDeviceNotFound);
    
    args = @[kProgramName, @"stop_simulating_location", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeDeviceNotFound);

    args = @[kProgramName, @"set_location", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE", @"-l", @"0,0"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeDeviceNotFound);
}

- (void)testMissingArg {
    NSArray *args = @[kProgramName, @"uninstall", @"-b"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);

    args = @[kProgramName, @"install", @"-a", @"fake/path/to/.app", @"-d"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

- (void)testOptionalArg {
    NSArray *args = @[kProgramName, @"install", @"-a", @"fake/path/to/.app"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);
    
    args = @[kProgramName, @"is_installed", @"-b", @"bundle_id"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeFalse);
}

- (void)testMissingRequiredOption {
    NSArray *args = @[kProgramName, @"install", @"-d", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

@end
