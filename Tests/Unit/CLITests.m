
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

- (void)testPositionalDeviceID {
    //SIM
    iOSReturnStatusCode ret;
    
    for (NSString *deviceID in @[@"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE", @"1234567890123456789012345678901234567890"]) {
        NSArray *args = @[kProgramName, @"uninstall", deviceID, @"-b", @"bundle_id"];
        ret = [CLI process:args];
        args = @[kProgramName, @"uninstall", @"-d", deviceID, @"-b", @"bundle_id"];
        XCTAssertEqual([CLI process:args], ret);
        XCTAssertEqual(ret, iOSReturnStatusCodeDeviceNotFound);
        
        args = @[kProgramName, @"stop_simulating_location", deviceID];
        ret = [CLI process:args];
        args = @[kProgramName, @"stop_simulating_location", @"-d", deviceID];
        XCTAssertEqual([CLI process:args], ret);
        XCTAssertEqual(ret, iOSReturnStatusCodeDeviceNotFound);

        args = @[kProgramName, @"set_location", deviceID, @"-l", @"0,0"];
        ret = [CLI process:args];
        args = @[kProgramName, @"set_location", @"-d", deviceID, @"-l", @"0,0"];
        XCTAssertEqual([CLI process:args], ret);
        XCTAssertEqual(ret, iOSReturnStatusCodeDeviceNotFound);
    }
    
    NSString *deviceID = @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE";
    NSArray *args = @[kProgramName, @"install", deviceID, @"-a", @"path/to/app/bundle"];
    ret = [CLI process:args];
    args = @[kProgramName, @"install", @"-d", deviceID, @"-a", @"path/to/app/bundle"];
    XCTAssertEqual([CLI process:args], ret);
    XCTAssertEqual(ret, iOSReturnStatusCodeDeviceNotFound);
    
    args = @[kProgramName, @"launch_simulator", deviceID];
    ret = [CLI process:args];
    args = @[kProgramName, @"launch_simulator", @"-d", deviceID];
    XCTAssertEqual([CLI process:args], ret);
    XCTAssertEqual(ret, iOSReturnStatusCodeDeviceNotFound);
    
    args = @[kProgramName, @"kill_simulator", deviceID];
    ret = [CLI process:args];
    args = @[kProgramName, @"kill_simulator", @"-d", deviceID];
    XCTAssertEqual([CLI process:args], ret);
    XCTAssertEqual(ret, iOSReturnStatusCodeDeviceNotFound);
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
    XCTAssertFalse([CLI process:args]);
    
    args = @[kProgramName, @"launch_simulator"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testMissingRequiredOption {
    NSArray *args = @[kProgramName, @"install", @"-d", @"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

@end
