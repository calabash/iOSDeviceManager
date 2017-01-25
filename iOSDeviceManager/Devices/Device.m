#import "PhysicalDevice.h"
#import "ShellRunner.h"
#import "Simulator.h"
#import "AppUtils.h"
#import "ConsoleWriter.h"
#import "DeviceUtils.h"

#define MUST_OVERRIDE @throw [NSException exceptionWithName:@"ProgrammerErrorException" reason:@"Method should be overridden by a subclass" userInfo:@{@"method" : NSStringFromSelector(_cmd)}]

@implementation Device

- (id)init {
    if (self = [super init]) {
        _testingComplete = NO;
    }
    return self;
}

+ (Device *)withID:(NSString *)uuid {
    if ([DeviceUtils isSimulatorID:uuid]) { return [Simulator withID:uuid]; }
    if ([DeviceUtils isDeviceID:uuid]) { return [PhysicalDevice withID:uuid]; }
    ConsoleWriteErr(@"Specified device ID does not match simulator or device");
    return nil;
}

+ (void)initialize {
    const char *FBLog = [ShellRunner verbose] ? "YES" : "NO";
    setenv("FBCONTROLCORE_LOGGING", FBLog, 1);
    setenv("FBCONTROLCORE_DEBUG_LOGGING", FBLog, 1);
}

- (iOSReturnStatusCode)launch {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)kill {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)installApp:(Application *)app shouldUpdate:(BOOL)shouldUpdate {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)simulateLocationWithLat:(double)lat lng:(double)lng {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)stopSimulatingLocation {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)launchApp:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)killApp:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)isInstalled:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (Application *)installedApp:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)startTestWithRunnerID:(NSString *)runnerID sessionID:(NSUUID *)sessionID keepAlive:(BOOL)keepAlive {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)uploadFile:(NSString *)filepath forApplication:(NSString *)bundleID overwrite:(BOOL)overwrite {
    MUST_OVERRIDE;
}

@end
