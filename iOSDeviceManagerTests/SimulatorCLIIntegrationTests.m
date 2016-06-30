
#import "iOSDeviceManagement.h"
#import <XCTest/XCTest.h>
#import "CLI.h"

@interface SimulatorCLIIntegrationTests : XCTestCase
@property (nonatomic, strong) NSString *simID;
@property (nonatomic, strong) NSString *unitTestAppPath;
@property (nonatomic, strong) NSString *taskyPath;
@property (nonatomic, strong) NSString *taskyID;
@property (nonatomic, strong) NSString *codesignIdentity;
@property (nonatomic, strong) NSString *testAppRunnerPath;
@property (nonatomic, strong) NSString *simTestBundlePath;
@property (nonatomic, strong) NSString *unitTestAppID;
@end

@implementation SimulatorCLIIntegrationTests

#define SUCCESS 0
#define FAILURE 1

static const NSString *progname = @"iOSDeviceManagement";

- (void)setUp {
    [super setUp];
    _taskyID = @"com.xamarin.samples.taskytouch";
    _unitTestAppID = @"sh.calaba.UnitTestApp";
    _simID = @"BFDFE518-E33E-407A-9EE8-A745CAA87099";
    _unitTestAppPath = @"/Users/chrisf/calabash-xcuitest-server/Products/app/UnitTestApp/UnitTestApp.app";
    _taskyPath = @"/Users/chrisf/Library/Developer/CoreSimulator/Devices/F8C4D65B-2FB7-4B8B-89BE-8C3982E65F3F/data/Containers/Bundle/Application/46C8D3C1-281F-418B-AF36-3DCE59FFFEB7/TaskyiOS.app";
    _codesignIdentity = @"iPhone Developer: Chris Fuentes (G7R46E5NX7)";
    _testAppRunnerPath = @"/Users/chrisf/calabash-xcuitest-server/Products/app/CBX-Runner.app";
    _simTestBundlePath = @"/Users/chrisf/calabash-xcuitest-server/Products/app/CBX-Runner.app/PlugIns/CBX.xctest";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testStartSimTest {
    NSArray *args = @[progname, @"launch_simulator", @"-d", _simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    setenv("DEVELOPER_DIR", "/Users/chrisf/Xcodes/8b1/Xcode-beta.app/Contents/Developer", YES);
    args = @[progname, @"start_test",
             @"-d", _simID,
             @"-t", _simTestBundlePath,
             @"-r", _testAppRunnerPath,
             @"-k", @"NO"];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testLaunchSim {
    NSArray *args = @[progname, @"launch_simulator", @"-d", _simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testKillSim {
    NSArray *args = @[progname, @"kill_simulator", @"-d", _simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testUninstallFromSim {
    NSArray *args = @[progname, @"kill_simulator", @"-d", _simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"uninstall", @"-d", _simID, @"-b", _unitTestAppID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeGenericFailure);
    
    args = @[progname, @"launch_simulator", @"-d", _simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"is_installed", @"-b", _unitTestAppID, @"-d", _simID];
    if ([CLI process:args] == iOSReturnStatusCodeFalse) {
        args = @[progname, @"install", @"-d", _simID, @"-a", _unitTestAppPath];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[progname, @"uninstall", @"-d", _simID, @"-b", _unitTestAppID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testInstallToSim {
    NSArray *args = @[progname, @"kill_simulator", @"-d", _simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"launch_simulator", @"-d", _simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"is_installed", @"-b", _taskyID, @"-d", _simID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[progname, @"uninstall", @"-d", _simID, @"-b", _taskyID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[progname, @"install", @"-d", _simID, @"-a", _taskyPath];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}

- (void)testAppIsInstalledOnSim {
    NSArray *args = @[progname, @"kill_simulator", @"-d", _simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"launch_simulator", @"-d", _simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"is_installed", @"-b", @"com.apple.Preferences", @"-d", _simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"is_installed", @"-b", _unitTestAppID, @"-d", _simID];
    if ([CLI process:args] == iOSReturnStatusCodeEverythingOkay) {
        args = @[progname, @"uninstall", @"-d", _simID, @"-b", _unitTestAppID];
        XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    }
    
    args = @[progname, @"is_installed", @"-b", _unitTestAppID, @"-d", _simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeFalse);

    args = @[progname, @"install", @"-d", _simID, @"-a", _unitTestAppPath];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
    
    args = @[progname, @"is_installed", @"-b", _unitTestAppID, @"-d", _simID];
    XCTAssertEqual([CLI process:args], iOSReturnStatusCodeEverythingOkay);
}


@end
