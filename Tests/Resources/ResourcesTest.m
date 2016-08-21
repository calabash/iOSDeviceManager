#import <XCTest/XCTest.h>
#import "TestCase.h"

@interface Instruments (XCTEST)

- (NSString *)extractUDID:(NSString *)string;
- (NSString *)extractVersion:(NSString *)string;

@end

@interface ResourcesTest : XCTestCase

@property(strong) Resources *resources;

@end

@implementation ResourcesTest

- (void)setUp {
    self.resources = [Resources shared];
    [Simctl shared];
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (BOOL)fileExists:(NSString *)path {
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

#pragma mark - Instruments

- (void)testUDIDRegex {
    NSString *string, *expected, *actual;

    string = @"hat (10.0) [e60ff9ae876ab4a218ee966d0525c9fb79e5606d]";
    expected = @"e60ff9ae876ab4a218ee966d0525c9fb79e5606d";
    actual = [[Instruments shared] extractUDID:string];
    XCTAssertEqualObjects(actual, expected);

    string = @"iPhone 5 (9.3) [D1B22B9C-F105-4DF0-8FA3-7AE41E212A9D] (Simulator)";
    actual = [[Instruments shared] extractUDID:string];
    NSLog(@"actual = %@", actual);
    XCTAssertNil(actual);
}

- (void)testVersionRegex {
    NSString *string, *expected, *actual;

    string = @"hat (10.0) [e60ff9ae876ab4a218ee966d0525c9fb79e5606d]";
    expected = @"10.0";
    actual = [[Instruments shared] extractVersion:string];
    XCTAssertEqualObjects(actual, expected);

    string = @"mercury (9.3.3) [5ddbd1cc1e0894a77811b3f41c8e5faecef3e912]";
    expected = @"9.3.3";
    actual = [[Instruments shared] extractVersion:string];
    XCTAssertEqualObjects(actual, expected);
}

- (void)testAvailableAndCompatibleDevices {
    NSLog(@"%@", [[Instruments shared] connectedDevices]);
    NSLog(@"%@", [[Instruments shared] compatibleDevices]);
    NSLog(@"%@", [[Instruments shared] deviceForTesting]);
}

#pragma mark - Xcode

- (void)testSetDeveloperDirectory {
    [self.resources setDeveloperDirectory];
}

#pragma mark - File System

- (void)testXCTestBundle {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSLog(@"RESOURCES DIR: %@", [bundle resourcePath]);
    NSLog(@"BUNDLE DIR: %@", [bundle bundlePath]);
    XCTAssertTrue([self fileExists:[self.resources resourcesDirectory]]);
}

- (void)testProcessInfo {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    NSLog(@"environment = %@", [info environment]);
    NSLog(@"arguments = %@", [info arguments]);
}

- (void)testApps {
    XCTAssertTrue([self fileExists:[self.resources TestAppPath:ARM]]);
    XCTAssertTrue([self fileExists:[self.resources TestAppPath:SIM]]);

    XCTAssertTrue([self fileExists:[self.resources TaskyPath:ARM]]);
    XCTAssertTrue([self fileExists:[self.resources TaskyPath:SIM]]);
    XCTAssertTrue([self fileExists:[self.resources TaskyIpaPath]]);

    XCTAssertTrue([self fileExists:[self.resources DeviceAgentPath:ARM]]);
    XCTAssertTrue([self fileExists:[self.resources DeviceAgentPath:SIM]]);

    XCTAssertTrue([self fileExists:[self.resources DeviceAgentXCTestPath:ARM]]);
    XCTAssertTrue([self fileExists:[self.resources DeviceAgentXCTestPath:SIM]]);
}

- (void)testInfoPlist {
    XCTAssertNotNil([self.resources TestAppPath:ARM]);
    XCTAssertNotNil([self.resources TestAppPath:SIM]);
}

- (void)testBundleIdentifier {
    NSString *arm = [self.resources bundleIdentifier:[self.resources TestAppPath:ARM]];
    NSString *sim = [self.resources bundleIdentifier:[self.resources TestAppPath:SIM]];
    NSString *identifier = [self.resources TestAppIdentifier];
    XCTAssertEqualObjects(arm, sim);
    XCTAssertEqualObjects(arm, identifier);

    arm = [self.resources bundleIdentifier:[self.resources DeviceAgentPath:ARM]];
    sim = [self.resources bundleIdentifier:[self.resources DeviceAgentPath:SIM]];
    identifier = [self.resources DeviceAgentIdentifier];
    XCTAssertEqualObjects(arm, sim);
    XCTAssertEqualObjects(arm, identifier);

    arm = [self.resources bundleIdentifier:[self.resources TaskyPath:ARM]];
    sim = [self.resources bundleIdentifier:[self.resources TaskyPath:SIM]];
    identifier = [self.resources TaskyIdentifier];
    XCTAssertEqualObjects(arm, sim);
    XCTAssertEqualObjects(arm, identifier);
}

- (void)testUniqueTmpDirectory {
    NSString *tmp = [self.resources uniqueTmpDirectory];
    XCTAssertTrue([self fileExists:tmp]);
}

- (void)testTmpDirectoryWithName {
    NSString *tmp = [self.resources tmpDirectoryWithName:@"Name"];
    XCTAssertTrue([self fileExists:tmp]);
}

- (void)testCopyDirectoryWithSourceTarget {
    NSString *source = [self.resources TestAppPath:SIM];
    NSString *target = [self.resources uniqueTmpDirectory];

    [self.resources copyDirectoryWithSource:source target:target];
    XCTAssertTrue([self fileExists:target]);
}

#pragma mark - Simctl

- (void)testSimctlShared {
    [Simctl shared];
}

#pragma mark - Simulators

- (void)testSimulators {
    NSArray *sims = [self.resources simulators];
    XCTAssertTrue([sims count] > 0);
    NSLog(@"%@", sims);
}

- (void)testDefaultSimulator {
    NSLog(@"%@", [self.resources defaultSimulator]);
    XCTAssertNotNil([self.resources defaultSimulator]);
}

- (void)testDefaultSimulatorUDID {
    NSLog(@"%@", [self.resources defaultSimulatorUDID]);
    XCTAssertNotNil([self.resources defaultSimulatorUDID]);
}

@end
