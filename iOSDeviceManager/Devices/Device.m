
#import "PhysicalDevice.h"
#import "ShellRunner.h"
#import "Simulator.h"

@implementation Device
+ (void)initialize {
    const char *FBLog = [ShellRunner verbose] ? "YES" : "NO";
    setenv("FBCONTROLCORE_LOGGING", FBLog, 1);
    setenv("FBCONTROLCORE_DEBUG_LOGGING", FBLog, 1);
}

+ (iOSReturnStatusCode)startTestOnDevice:(NSString *)deviceID
                          testRunnerPath:(NSString *)testRunnerPath
                          testBundlePath:(NSString *)testBundlePath
                        codesignIdentity:(NSString *)codesignIdentity
                               keepAlive:(BOOL)keepAlive {
    if ([TestParameters isDeviceID:deviceID]) {
        return [PhysicalDevice startTestOnDevice:deviceID
                                  testRunnerPath:testRunnerPath
                                  testBundlePath:testBundlePath
                                codesignIdentity:codesignIdentity
                                       keepAlive:keepAlive];
    } else {
        return [Simulator startTestOnDevice:deviceID
                             testRunnerPath:testRunnerPath
                             testBundlePath:testBundlePath
                           codesignIdentity:codesignIdentity
                                  keepAlive:keepAlive];
    }
}

+ (iOSReturnStatusCode)installApp:(NSString *)pathToBundle
                         deviceID:(NSString *)deviceID
                       codesignID:(NSString *)codesignID {
    if ([TestParameters isDeviceID:deviceID]) {
        return [PhysicalDevice installApp:pathToBundle
                                 deviceID:deviceID
                               codesignID:codesignID];
    } else {
        return [Simulator installApp:pathToBundle
                            deviceID:deviceID
                          codesignID:nil];
    }
}

+ (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID
                           deviceID:(NSString *)deviceID {
    if ([TestParameters isSimulatorID:deviceID]) {
        return [Simulator uninstallApp:bundleID deviceID:deviceID];
    } else {
        return [PhysicalDevice uninstallApp:bundleID deviceID:deviceID];
    }
}

+ (iOSReturnStatusCode)appIsInstalled:(NSString *)bundleID
                             deviceID:(NSString *)deviceID {
    if ([TestParameters isSimulatorID:deviceID]) {
        return [Simulator appIsInstalled:bundleID deviceID:deviceID];
    } else {
        return [PhysicalDevice appIsInstalled:bundleID deviceID:deviceID];
    }
}

+ (iOSReturnStatusCode)setLocation:(NSString *)deviceID
                               lat:(double)lat
                               lng:(double)lng {
    if ([TestParameters isSimulatorID:deviceID]) {
        return [Simulator setLocation:deviceID
                                  lat:lat
                                  lng:lng];
    } else {
        return [PhysicalDevice setLocation:deviceID
                                       lat:lat
                                       lng:lng];
    }
}

@end
