
#import "PhysicalDevice.h"
#import "Simulator.h"

@implementation Device
+ (iOSReturnStatusCode)startTestOnDevice:(NSString *)deviceID
                          testRunnerPath:(NSString *)testRunnerPath
                          testBundlePath:(NSString *)testBundlePath
                        codesignIdentity:(NSString *)codesignIdentity {
    if ([TestParameters isDeviceID:deviceID]) {
        return [PhysicalDevice startTestOnDevice:deviceID
                                  testRunnerPath:testRunnerPath
                                  testBundlePath:testBundlePath
                                codesignIdentity:codesignIdentity];
    } else {
        return [Simulator startTestOnDevice:deviceID
                             testRunnerPath:testRunnerPath
                             testBundlePath:testBundlePath
                           codesignIdentity:codesignIdentity];
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

@end
