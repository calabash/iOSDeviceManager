
#import "iOSDeviceManagement.h"
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
        return [Device startTestOnDevice:STR(deviceID)
                          testRunnerPath:STR(testRunnerPath)
                          testBundlePath:STR(testBundlePath)
                        codesignIdentity:STR(codesignID)
                               keepAlive:YES];
    }
}

int install_app(const char *pathToBundle,
                const char *deviceID,
                const char *codesignID) {
    @autoreleasepool {
        return [Device installApp:STR(pathToBundle)
                         deviceID:STR(deviceID)
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
        //Returns 1, 0, or -1 for 'true', 'false', 'error'
        return [Device appIsInstalled:STR(bundleID)
                             deviceID:STR(deviceID)];
    }
}
