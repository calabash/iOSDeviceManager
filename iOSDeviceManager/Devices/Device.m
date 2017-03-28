#import "PhysicalDevice.h"
#import "ShellRunner.h"
#import "Simulator.h"
#import "AppUtils.h"
#import "ConsoleWriter.h"
#import "DeviceUtils.h"
#import "JSONUtils.h"
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
                                                   waitForDebugger:NO
                                                   output:[FBProcessOutputConfiguration defaultForDeviceManager]];
    FBiOSDeviceOperator *deviceOperator = [iOSTarget deviceOperator];
    if (![deviceOperator launchApplication:appLaunch error:&innerError]) {
        if (error) {
            *error = [[[XCTestBootstrapError describe:@"Failed launch test runner"]
                       causedBy:innerError]
                      fail:error];
        }
        return nil;
    }

    pid_t testRunnerProcessID = [deviceOperator processIDWithBundleID:bundleID
                                                                error:&innerError];

    if (testRunnerProcessID < 1) {
        if (error) {
            *error = [[[XCTestBootstrapError
                       describe:@"Failed to determine test runner process PID"]
                       causedBy:innerError]
                      fail:error];
        }
        return nil;
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


    // Unexpected: returns non-nil if there is a failure.
    FBTestManagerResult *result = [testManager connectWithTimeout:FBControlCoreGlobalConfiguration.regularTimeout];
    if (result) {
        if (error) {
            *error = [[[XCTestBootstrapError
                        describeFormat:@"Test Manager Connection Failed: %@", result.description]
                       causedBy:result.error]
                      fail:error];
        }
        return nil;
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

+ (instancetype)withID:(NSString *)uuid {
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

#pragma mark - Instance Methods

- (BOOL)shouldUpdateApp:(Application *)app statusCode:(iOSReturnStatusCode *)sc {
    NSError *isInstalledError;
    if ([self isInstalled:app.bundleID withError:&isInstalledError]) {
        Application *installedApp = [self installedApp:app.bundleID];
        NSDictionary *oldPlist = installedApp.infoPlist;
        NSDictionary *newPlist = app.infoPlist;
        
        if (!oldPlist.count) {
            ConsoleWriteErr(@"Error fetching/parsing plist from installed application $@", installedApp.bundleID);
            *sc = iOSReturnStatusCodeGenericFailure;
            return NO;
        }
        
        if (!newPlist.count) {
            ConsoleWriteErr(@"Unable to find Info.plist for bundle path %@", app.path);
            *sc = iOSReturnStatusCodeGenericFailure;
            return NO;
        }
        
        if ([AppUtils appVersionIsDifferent:oldPlist newPlist:newPlist]) {
            ConsoleWriteErr(@"Installed version is different, attempting to update %@.", app.bundleID);
            return YES;
        } else {
            ConsoleWriteErr(@"Latest version of %@ is installed, not reinstalling.", app.bundleID);
            return NO;
        }
    }
    
    //If it's not installed, it should be 'updated'
    return YES;
}

- (BOOL)isInstalled:(NSString *)bundleID withError:(NSError **)error {
    MUST_OVERRIDE;
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

- (iOSReturnStatusCode)installApp:(Application *)app
                    mobileProfile:(MobileProfile *)profile
                     shouldUpdate:(BOOL)shouldUpdate {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)installApp:(Application *)app
                codesignIdentity:(CodesignIdentity *)codesignID
                    shouldUpdate:(BOOL)shouldUpdate {
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

- (NSString *)containerPathForApplication:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (NSString *)installPathForApplication:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (NSString *)xctestBundlePathForTestRunnerAtPath:(NSString *)testRunnerPath {
    if (![testRunnerPath hasSuffix:@"-Runner.app"]) {
        NSString *name = [testRunnerPath lastPathComponent];
        ConsoleWriteErr(@"Expected test runner '%@' to end with -Runner.app", name);
        ConsoleWriteErr(@"Cannot detect xctestBundlePath from test runner path:");
        ConsoleWriteErr(@"  %@", testRunnerPath);
        return nil;
    }

    NSArray *tokens = [[testRunnerPath lastPathComponent]
                                       componentsSeparatedByString:@"-Runner.app"];
    if ([tokens count] != 2) {
        NSString *name = [testRunnerPath lastPathComponent];
        ConsoleWriteErr(@"Expected test runner '%@' to end with -Runner.app", name);
        ConsoleWriteErr(@"Cannot detect xctestBundlePath from test runner path:");
        ConsoleWriteErr(@"  %@", testRunnerPath);
        return nil;
    }

    NSString *bundleName = [NSString stringWithFormat:@"%@.xctest", tokens[0]];
    NSString *bundlePath = [@"PlugIns" stringByAppendingPathComponent:bundleName];
    return [testRunnerPath stringByAppendingPathComponent:bundlePath];
}

- (BOOL)stageXctestConfigurationToTmpForBundleIdentifier:(NSString *)bundleIdentifier
                                                   error:(NSError **)error {
    MUST_OVERRIDE;
}

@end
