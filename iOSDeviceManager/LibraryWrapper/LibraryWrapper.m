#import "LibraryWrapper.h"

#define STR( cString ) [NSString stringWithCString:( cString ) encoding:NSUTF8StringEncoding]

int launch_simulator(const char *simulatorID) {
    @autoreleasepool {
        NSString *simID = STR(simulatorID);
        NSArray<NSString *> *args = @[@"launch_simulator", simID];
        return [CLI process:args];
    }
}

int kill_simulator(const char *simulatorID) {
    @autoreleasepool {
        NSString *simID = STR(simulatorID);
        NSArray<NSString *> *args = @[@"kill_simulator", simID];
        return [CLI process:args];
    }
}

int install_app(const char *pathToApp, const char *deviceID, const char *pathToProfile) {
    @autoreleasepool {
        NSString *appPath = STR(pathToApp);
        NSString *deviceIDStr = STR(deviceID);
        NSString *profilePath = STR(pathToProfile);
        NSArray<NSString *> *args = @[@"install", appPath, deviceIDStr, profilePath];
        return [CLI process:args];
    }
}

int uninstall_app(const char *bundleID, const char *deviceID) {
    @autoreleasepool {
        NSString *deviceIDStr = STR(deviceID);
        NSString *appID = STR(bundleID);
        NSArray<NSString *> *args = @[@"uninstall", appID, deviceIDStr];
        return [CLI process:args];
    }
}

int is_installed(const char *bundleID, const char *deviceID) {
    @autoreleasepool {
        NSString *deviceIDStr = STR(deviceID);
        NSString *appID = STR(bundleID);
        NSArray<NSString *> *args = @[@"is_installed", appID, deviceIDStr];
        return [CLI process:args];
    }
}
