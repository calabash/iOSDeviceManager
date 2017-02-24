#import "PhysicalDevice.h"
#import "ShellRunner.h"
#import "Simulator.h"
#import "AppUtils.h"
#import "ConsoleWriter.h"
#import "DeviceUtils.h"
#import <XCTestBootstrap/XCTestBootstrap.h>

#define MUST_OVERRIDE @throw [NSException exceptionWithName:@"ProgrammerErrorException" reason:@"Method should be overridden by a subclass" userInfo:@{@"method" : NSStringFromSelector(_cmd)}]

@implementation FBProcessOutputConfiguration (iOSDeviceManagerAdditions)

+ (FBProcessOutputConfiguration *)defaultForDeviceManager {
    return [FBProcessOutputConfiguration outputToDevNull];
}

@end


@implementation FBXCTestRunStrategy (iOSDeviceManagerAdditions)

+ (FBTestManager *)startTestManagerForIOSTarget:(id<FBiOSTarget>)iOSTarget
                                 runnerBundleID:(NSString *)bundleID
                                      sessionID:(NSUUID *)sessionID
                                 withAttributes:(NSArray *)attributes
                                    environment:(NSDictionary *)environment
                                       reporter:(id<FBTestManagerTestReporter>)reporter
                                         logger:(id<FBControlCoreLogger>)logger
                                          error:(NSError *__autoreleasing *)error {
    NSAssert(bundleID, @"Must provide test runner bundle ID in order to run a test");
    NSAssert(sessionID, @"Must provide a test session ID in order to run a test");

    NSError *innerError;

    FBApplicationLaunchConfiguration *appLaunch = [FBApplicationLaunchConfiguration
                                                   configurationWithBundleID:bundleID
                                                   bundleName:bundleID
                                                   arguments:attributes ?: @[]
                                                   environment:environment ?: @{}
                                                   output:[FBProcessOutputConfiguration defaultForDeviceManager]];
    FBiOSDeviceOperator *deviceOperator = [iOSTarget deviceOperator];
    if (![deviceOperator launchApplication:appLaunch error:&innerError]) {
        return [[[XCTestBootstrapError describe:@"Failed launch test runner"]
                 causedBy:innerError]
                fail:error];
    }

    pid_t testRunnerProcessID = [deviceOperator processIDWithBundleID:bundleID error:error];

    if (testRunnerProcessID < 1) {
        return [[XCTestBootstrapError
                 describe:@"Failed to determine test runner process PID"]
                fail:error];
    }

    FBTestManagerContext *context =
    [FBTestManagerContext contextWithTestRunnerPID:testRunnerProcessID
                                testRunnerBundleID:bundleID
                                 sessionIdentifier:sessionID];

    // Attach to the XCTest Test Runner host Process.
    FBTestManager *testManager = [FBTestManager testManagerWithContext:context
                                                             iosTarget:iOSTarget
                                                              reporter:reporter
                                                                logger:logger];

    FBTestManagerResult *result = [testManager connectWithTimeout:FBControlCoreGlobalConfiguration.regularTimeout];
    if (result) {
        return [[[XCTestBootstrapError
                  describeFormat:@"Test Manager Connection Failed: %@", result.description]
                 causedBy:result.error]
                fail:error];
    }
    return testManager;
}

@end

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

- (BOOL)isInstalled:(NSString *)bundleID statusCode:(iOSReturnStatusCode *)statusCode {
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

- (pid_t)pidForBundleID:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (BOOL)appIsRunning:(NSString *)bundleID {
    return [self pidForBundleID:bundleID] > 0;
}

@end
