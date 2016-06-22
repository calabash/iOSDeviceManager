
#import "XCTestControlWrapper.h"
#import "DeviceTestParameters.h"
#import "TestControlArgParser.h"
#import "Simulator.h"
#import "Device.h"

#define SUCCESS 0
#define FAILURE 1
#define STR( cString ) [NSString stringWithCString:( cString ) encoding:NSUTF8StringEncoding]

int start_test(const char *deviceID,
               const char *testRunnerPath,
               const char *testBundlePath,
               const char *codesignID) {
    @autoreleasepool {
        TestParameters *params = [TestParameters fromJSON:@{
                                                            DEVICE_ID_FLAG : STR(deviceID) ?: @"",
                                                            TEST_RUNNER_PATH_FLAG : STR(testRunnerPath) ?: @"",
                                                            XCTEST_BUNDLE_PATH_FLAG : STR(testBundlePath) ?: @"",
                                                            CODESIGN_IDENTITY_FLAG : STR(codesignID) ?: @""
                                                            }];
        
        return [Device startTest:params] ? SUCCESS : FAILURE;
    }
}

int install_app(const char *pathToBundle,
                const char *deviceID,
                const char *codesignID) {
    @autoreleasepool {
        return [Device installApp:STR(pathToBundle)
                         deviceID:STR(deviceID)
                       codesignID:STR(codesignID)] ? SUCCESS : FAILURE;
    }
}

int launch_simulator(const char *simulatorID) {
    @autoreleasepool {
        return [Simulator launchSimulator:STR(simulatorID)] ? SUCCESS : FAILURE;
    }
}

int kill_simulator(const char *simulatorID) {
    @autoreleasepool {
        return [Simulator killSimulator:STR(simulatorID)] ? SUCCESS : FAILURE;
    }
}

int uninstall_app(const char *bundleID, const char *deviceID) {
    @autoreleasepool {
        return [Device uninstallApp:STR(bundleID) deviceID:STR(deviceID)] ? SUCCESS : FAILURE;
    }
}

int is_installed(const char *bundleID, const char *deviceID) {
    @autoreleasepool {
        //Returns 1, 0, or -1 for 'true', 'false', 'error'
        return [Device appIsInstalled:STR(bundleID) deviceID:STR(deviceID)];
    }
}

int clear_app_data(const char *bundleID, const char *deviceID) {
    @autoreleasepool {
        return [Device clearAppData:STR(bundleID) deviceID:STR(deviceID)] ? SUCCESS : FAILURE;
    }
}
