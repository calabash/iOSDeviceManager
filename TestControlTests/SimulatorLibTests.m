
#import <XCTest/XCTest.h>
#import "XCTestControlWrapper.h"

@interface SimulatorLibTests : XCTestCase
@property (nonatomic) const char *simID;
@property (nonatomic) const char *unitTestAppPath;
@property (nonatomic) const char *taskyPath;
@property (nonatomic) const char *taskyID;
@property (nonatomic) const char *codesignIdentity;
@property (nonatomic) const char *testAppRunnerPath;
@property (nonatomic) const char *simTestBundlePath;
@property (nonatomic) const char *unitTestAppID;
@end

@implementation SimulatorLibTests

#define SUCCESS 0
#define FAILURE 1

- (void)setUp {
    [super setUp];
    
    _taskyID = "com.xamarin.samples.taskytouch";
    _unitTestAppID = "sh.calaba.UnitTestApp";
    _simID = "BFDFE518-E33E-407A-9EE8-A745CAA87099";
    _unitTestAppPath = "/Users/chrisf/calabash-xcuitest-server/Products/app/UnitTestApp/UnitTestApp.app";
    _taskyPath = "/Users/chrisf/Library/Developer/CoreSimulator/Devices/F8C4D65B-2FB7-4B8B-89BE-8C3982E65F3F/data/Containers/Bundle/Application/46C8D3C1-281F-418B-AF36-3DCE59FFFEB7/TaskyiOS.app";
    _codesignIdentity = "iPhone Developer: Chris Fuentes (G7R46E5NX7)";
    _testAppRunnerPath = "/Users/chrisf/calabash-xcuitest-server/Products/app/CBX-Runner.app";
    _simTestBundlePath = "/Users/chrisf/calabash-xcuitest-server/Products/app/CBX-Runner.app/PlugIns/CBX.xctest";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (void)testStartSimTest {
//    //FIXME:
//    //find some way to end the test
//    XCTAssertEqual(start_test(_simID, _testAppRunnerPath, _simTestBundlePath, _codesignIdentity), SUCCESS);
//}

- (void)testLaunchSim {
    XCTAssertEqual(launch_simulator(_simID), SUCCESS);
}

- (void)testKillSim {
    XCTAssertEqual(kill_simulator(_simID), SUCCESS);
}

- (void)testUninstallFromSim {
    kill_simulator(_simID);
    XCTAssertEqual(uninstall_app(_unitTestAppID, _simID), FAILURE);
    launch_simulator(_simID);
    XCTAssertEqual(uninstall_app(_unitTestAppID, _simID), SUCCESS);
}

- (void)testInstallToSim {
    kill_simulator(_simID);
    XCTAssertEqual(install_app(_taskyPath, _simID, _codesignIdentity), FAILURE);
    launch_simulator(_simID);
    XCTAssertEqual(install_app(_taskyPath, _simID, _codesignIdentity), SUCCESS);
}

- (void)testAppIsInstalledOnSim {
    XCTAssertTrue(is_installed("com.apple.Preferences", _simID) == 1);
    
    if (is_installed(_unitTestAppID, _simID)) {
        uninstall_app(_unitTestAppID, _simID);
    }
    XCTAssertTrue(is_installed(_unitTestAppID, _simID) == 0);
    install_app(_unitTestAppPath, _simID, _codesignIdentity);
    XCTAssertTrue(is_installed(_unitTestAppID, _simID) == 1);
}


@end
