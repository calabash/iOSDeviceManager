
#import "iOSDeviceManagement.h"
#import "PhysicalDevice.h"
#import "Simulator.h"

#define SUCCESS 0
#define FAILURE 1
#define STR( cString ) [NSString stringWithCString:( cString ) encoding:NSUTF8StringEncoding]

int start_test(const char *deviceID,
               const char *testRunnerPath,
               const char *testBundlePath,
               const char *codesignID,
               int updateRunner) {
    @autoreleasepool {
        return [Device startTestOnDevice:STR(deviceID)
                          testRunnerPath:STR(testRunnerPath)
                          testBundlePath:STR(testBundlePath)
                        codesignIdentity:STR(codesignID)
                        updateTestRunner:updateRunner
                               keepAlive:YES];
    }
}

int install_app(const char *pathToBundle,
                const char *deviceID,
                const char *codesignID) {
    @autoreleasepool {
        return [Device installApp:STR(pathToBundle)
                         deviceID:STR(deviceID)
                        updateApp:YES
                       codesignID:STR(codesignID)];
    }
}

int launch_simulator(const char *simulatorID) {
    @autoreleasepool {
        return [Simulator launchSimulator:STR(simulatorID)];
    }
}

int kill_simulator(const char *simulatorID) {
    @autoreleasepool {
        return [Simulator killSimulator:STR(simulatorID)];
    }
}

int uninstall_app(const char *bundleID, const char *deviceID) {
    @autoreleasepool {
        return [Device uninstallApp:STR(bundleID)
                           deviceID:STR(deviceID)];
    }
}

int is_installed(const char *bundleID, const char *deviceID) {
    @autoreleasepool {
        return [Device appIsInstalled:STR(bundleID)
                             deviceID:STR(deviceID)];
    }
}

int simulate_location(const char *deviceID, double lat, double lng) {
    @autoreleasepool {
        return [Device setLocation:STR(deviceID)
                               lat:lat
                               lng:lng];
    }
}

int stop_simulating_location(const char *deviceID) {
    @autoreleasepool {
        return [PhysicalDevice stopSimulatingLocation:STR(deviceID)];
    }
}
