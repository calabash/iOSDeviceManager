
#import <XCTest/XCTest.h>
#import "CLI.h"

@interface CLITests : XCTestCase

@end

@implementation CLITests

static const NSString *progname = @"iOSDeviceManager";

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNoArgs {
    XCTAssertEqual([CLI process:@[progname]], iOSReturnStatusCodeEverythingOkay);
}

- (void)testInvalidCommandName {
    NSArray *args = @[progname, @"foooooozeball"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeUnrecognizedCommand);
}

- (void)testNoArguments {
    NSArray *args = @[progname, @"uninstall"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

- (void)testInvalidFlag {
    NSArray *args = @[progname, @"uninstall", @"-z"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeUnrecognizedFlag);
}

- (void)testMissingArg {
    NSArray *args = @[progname, @"uninstall", @"-b"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
    
    args = @[progname, @"install", @"-a", @"fake/path/to/.app", @"-d"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

- (void)testMissingRequiredOption {
    NSArray *args = @[progname, @"install", @"-a", @"fake/path/to/.app"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeMissingArguments);
}

@end
