
#import "TestCase.h"
#import "Device.h"
#import "CLI.h"

@interface DeviceTest : TestCase

@end

@implementation DeviceTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testGenerateXCAppDataBundleAtPath {
    NSString *path = [[[Resources shared] uniqueTmpDirectory]
                      stringByAppendingPathComponent:@"Test.xcappdata"];

    // create
    expect([Device generateXCAppDataBundleAtPath:path
                                       overwrite:NO]).to.equal(iOSReturnStatusCodeEverythingOkay);

    // does not delete existing
    expect([Device generateXCAppDataBundleAtPath:path
                                       overwrite:NO]).to.equal(iOSReturnStatusCodeGenericFailure);

    // deletes existing
    expect([Device generateXCAppDataBundleAtPath:path
                                       overwrite:YES]).to.equal(iOSReturnStatusCodeEverythingOkay);
}

- (void)testGenerateCLI {
    NSArray *args = @[kProgramName, @"generate-xcappdata"];
    expect([CLI process:args]).to.equal(iOSReturnStatusCodeMissingArguments);

    NSString *name = [[[Resources shared] uniqueTmpDirectory]
                      stringByAppendingPathComponent:@"My.xcappdata"];
    args = @[kProgramName, @"generate-xcappdata", name];
    expect([CLI process:args]).to.equal(iOSReturnStatusCodeEverythingOkay);

    // expands ~/ and creates intermediate directories
    NSString *UUID = [[NSProcessInfo processInfo] globallyUniqueString];
    name = [NSString stringWithFormat:@"~/.iOSDeviceManager/Tests/%@/My.xcappdata", UUID];
    args = @[kProgramName, @"generate-xcappdata", name];
    expect([CLI process:args]).to.equal(iOSReturnStatusCodeEverythingOkay);

    // fails if xcappdata bundle exists
    args = @[kProgramName, @"generate-xcappdata", name];
    expect([CLI process:args]).to.equal(iOSReturnStatusCodeGenericFailure);

    // can overwrite with args
    args = @[kProgramName, @"generate-xcappdata", name, @"--overwrite", @(YES)];
    expect([CLI process:args]).to.equal(iOSReturnStatusCodeEverythingOkay);

    // can overwrite with args
    args = @[kProgramName, @"generate-xcappdata", name, @"-o", @(YES)];
    expect([CLI process:args]).to.equal(iOSReturnStatusCodeEverythingOkay);
}

@end
