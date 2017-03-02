
#import "Simulator.h"
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "ShellRunner.h"
#import "AppUtils.h"
#import "Codesigner.h"
#import "ConsoleWriter.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@interface Simulator()

@property (nonatomic, strong) FBSimulator *fbSimulator;

@end

@implementation Simulator

static const FBSimulatorControl *_control;

+ (void)initialize {
    FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration
        configurationWithDeviceSetPath:nil
                               options:FBSimulatorManagementOptionsIgnoreSpuriousKillFail];

    NSError *error;
    _control = [FBSimulatorControl withConfiguration:configuration error:&error];
    if (error) {
        ConsoleWriteErr(@"Error creating FBSimulatorControl: %@", error);
        abort();
    }
}

+ (Device *)withID:(NSString *)uuid {
    Simulator* simulator = [[Simulator alloc] init];

    simulator.uuid = uuid;

    FBSimulatorSet *sims = _control.set;
    if (!sims) {
        ConsoleWriteErr(@"Unable to retrieve simulators");
        return nil;
    }

    FBiOSTargetQuery *query = [FBiOSTargetQuery udids:@[uuid]];
    NSArray <FBSimulator *> *results = [sims query:query];
    if (results.count == 0) {
        ConsoleWriteErr(@"No simulators found for ID %@", uuid);
        return nil;
    }

    simulator.fbSimulator = results[0];

    return simulator;
}

- (iOSReturnStatusCode)launch {

    NSError *error;
    if (self.fbSimulator.state == FBSimulatorStateShutdown ||
        self.fbSimulator.state == FBSimulatorStateShuttingDown) {
        LogInfo(@"Sim is dead, booting...");

        FBSimulatorBootConfiguration *bootConfig;

        // FBSimulatorBootOptionsAwaitServices - would this allow us to wait until the
        // simulator is booted?
        bootConfig = [FBSimulatorBootConfiguration withOptions:FBSimulatorBootOptionsConnectBridge];
        FBSimulatorInteraction *interaction;
        interaction = [FBSimulatorInteraction withSimulator:self.fbSimulator];

        if (![[interaction bootSimulator:bootConfig] perform:&error]) {
            ConsoleWriteErr(@"Failed to boot sim: %@", error);
            return iOSReturnStatusCodeInternalError;
        }
    }

    return self.fbSimulator != nil ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeDeviceNotFound;
}

- (iOSReturnStatusCode)kill {

    if (self.fbSimulator == nil) {
        ConsoleWriteErr(@"No such simulator exists!");
        return iOSReturnStatusCodeDeviceNotFound;
    }
    if (self.fbSimulator.state == FBSimulatorStateShutdown) {
        ConsoleWriteErr(@"Simulator %@ is already shut down", [self uuid]);
        return iOSReturnStatusCodeEverythingOkay;
    } else if (self.fbSimulator.state == FBSimulatorStateShuttingDown) {
        ConsoleWriteErr(@"Simulator %@ is already shutting down", [self uuid]);
        return iOSReturnStatusCodeEverythingOkay;
    }

    NSError *e;
    [[self.fbSimulator.interact shutdownSimulator] perform:&e];

    if (e ) {
        ConsoleWriteErr(@"Error shutting down sim %@: %@", [self uuid], e);
    }

    return e == nil ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeInternalError;
}

- (iOSReturnStatusCode)installApp:(Application *)app shouldUpdate:(BOOL)shouldUpdate {
    NSError *e;
    if (!self.fbSimulator) { return iOSReturnStatusCodeDeviceNotFound; }

    if (self.fbSimulator.state == FBSimulatorStateShutdown ||
        self.fbSimulator.state == FBSimulatorStateShuttingDown) {
        ConsoleWriteErr(@"Simulator %@ is dead. Must launch sim before installing an app.", [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    Codesigner *signer = [[Codesigner alloc] initAdHocWithDeviceUDID:[self uuid]];

    if (![signer validateSignatureAtBundlePath:app.path]) {
        NSError *signError;

        [signer signBundleAtPath:app.path
                           error:&signError];

        if (signError) {
            ConsoleWriteErr(@"Error resigning sim bundle");
            ConsoleWriteErr(@"  Path to bundle: %@", app.path);
            ConsoleWriteErr(@"  Device UDID: %@", [self uuid]);
            ConsoleWriteErr(@"  ERROR: %@", signError);
            return iOSReturnStatusCodeGenericFailure;
        }
    }

    NSError *error;
    FBApplicationDescriptor *appDescriptor = [FBApplicationDescriptor userApplicationWithPath:app.path
                                                                                        error:&error];
    if (error) {
        ConsoleWriteErr(@"Error creating application descriptor");
        ConsoleWriteErr(@" Path to bundle: %@", app.path);
        return iOSReturnStatusCodeGenericFailure;
    }

    if (![self.fbSimulator installedApplicationWithBundleID:app.bundleID error:nil]) {
        [[self.fbSimulator.interact installApplication:appDescriptor] perform:&e];
    } else if (shouldUpdate) {
        iOSReturnStatusCode ret = [self updateInstalledAppIfNecessary:app];
        if (ret != iOSReturnStatusCodeEverythingOkay) {
            return ret;
        }
    }

    if (e) {
        ConsoleWriteErr(@"Error installing application: %@", e);
        return iOSReturnStatusCodeGenericFailure;
    } else {
        DDLogInfo(@"Installed %@ to %@", app.bundleID, [self uuid]);
    }

    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID {

    if (self.fbSimulator == nil) {
        ConsoleWriteErr(@"No such simulator exists!");
        return iOSReturnStatusCodeDeviceNotFound;
    }

    if (self.fbSimulator.state == FBSimulatorStateShutdown ||
        self.fbSimulator.state == FBSimulatorStateShuttingDown) {
        ConsoleWriteErr(@"Simulator %@ is dead. Must launch before uninstalling apps.", [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    if (![self.fbSimulator installedApplicationWithBundleID:bundleID error:nil]) {
        ConsoleWriteErr(@"App %@ is not installed on %@", bundleID, [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    [[self.fbSimulator.interact uninstallApplicationWithBundleID:bundleID] perform:&e];
    if (e) {
        ConsoleWriteErr(@"Error uninstalling app: %@", e);
    }

    return e == nil ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeInternalError;
}

- (iOSReturnStatusCode)simulateLocationWithLat:(double)lat
                                           lng:(double)lng {

    if (self.fbSimulator == nil) {
        ConsoleWriteErr(@"No such simulator exists!");
        return iOSReturnStatusCodeDeviceNotFound;
    }

    if (self.fbSimulator.state == FBSimulatorStateShutdown ||
        self.fbSimulator.state == FBSimulatorStateShuttingDown) {
        ConsoleWriteErr(@"Sim is dead! Must boot first");
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    FBSimulatorBridge *bridge = [FBSimulatorBridge bridgeForSimulator:self.fbSimulator error:&e];
    if (e || !bridge) {
        ConsoleWriteErr(@"Unable to fetch simulator bridge: %@", e);
        return iOSReturnStatusCodeInternalError;
    }

    [bridge setLocationWithLatitude:lat longitude:lng];

    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)stopSimulatingLocation {
    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)launchApp:(NSString *)bundleID {

    NSError *error;
    if ([self isInstalled:bundleID withError:error]) {

        FBApplicationLaunchConfiguration *config;
        config = [FBApplicationLaunchConfiguration configurationWithBundleID:bundleID
                                                                  bundleName:nil
                                                                   arguments:@[]
                                                                 environment:@{}
                                                                      output:[FBProcessOutputConfiguration defaultForDeviceManager]];
        if ([self.fbSimulator launchApplication:config error:nil]) {
            return iOSReturnStatusCodeEverythingOkay;
        } else {
            return iOSReturnStatusCodeInternalError;
        }
    }

    return iOSReturnStatusCodeGenericFailure;
}

- (iOSReturnStatusCode)killApp:(NSString *)bundleID {
    BOOL result = [self.fbSimulator killApplicationWithBundleID:bundleID error:nil];

    if (result) {
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        return iOSReturnStatusCodeFalse;
    }
}

- (BOOL) isInstalled:(NSString *)bundleID withError:(NSError *)error {

    BOOL installed = [self.fbSimulator isApplicationInstalledWithBundleID:bundleID error:&error];

    if (installed) {
        return YES;
    } else {
        return NO;
    }
}

- (iOSReturnStatusCode)isInstalled:(NSString *)bundleID {

    NSError *e;
    BOOL installed = [self isInstalled:bundleID withError:e];

    if (e) {
        LogInfo(@"Error checking if %@ is installed to %@: %@", bundleID, [self uuid], e);
        return iOSReturnStatusCodeFalse;
    }

    if (installed) {
        [ConsoleWriter write:@"true"];
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        [ConsoleWriter write:@"false"];
        return iOSReturnStatusCodeFalse;
    }

}

- (Application *)installedApp:(NSString *)bundleID {
    FBApplicationDescriptor *installed = [self.fbSimulator installedApplicationWithBundleID:bundleID error:nil];
    if (!installed) {
        return nil;
    }

    return [Application withBundlePath:installed.path];
}

- (iOSReturnStatusCode)startTestWithRunnerID:(NSString *)runnerID sessionID:(NSUUID *)sessionID keepAlive:(BOOL)keepAlive {

    NSError *e;
    if (self.fbSimulator.state == FBSimulatorStateShutdown ) {
        [[self.fbSimulator.interact bootSimulator] perform:&e];
        DDLogInfo(@"Sim is dead, booting.");
        if (e) {
            ConsoleWriteErr(@"Error booting simulator %@ for test: %@", [self uuid], e);
            return iOSReturnStatusCodeInternalError;
        }
    }

    NSError *error;
    if ([self isInstalled:runnerID withError:error] == iOSReturnStatusCodeFalse) {
        ConsoleWriteErr(@"TestRunner %@ must be installed before you can run a test.", runnerID);
        return iOSReturnStatusCodeGenericFailure;
    }


    Simulator *replog = [Simulator new];
    [XCTestBootstrapFrameworkLoader loadPrivateFrameworksOrAbort];
    FBTestManager *testManager = [FBXCTestRunStrategy startTestManagerForIOSTarget:self.fbSimulator
                                                                    runnerBundleID:runnerID
                                                                         sessionID:sessionID
                                                                    withAttributes:[FBTestRunnerConfigurationBuilder defaultBuildAttributes]
                                                                       environment:[FBTestRunnerConfigurationBuilder defaultBuildEnvironment]
                                                                          reporter:replog
                                                                            logger:replog
                                                                             error:&e];

    if (e) {
        ConsoleWriteErr(@"Error starting test runner: %@", e);
        return iOSReturnStatusCodeInternalError;
    } else if (keepAlive) {
        /*
         `testingComplete` will be YES when testmanagerd calls
         `testManagerMediatorDidFinishExecutingTestPlan:`
         */
        while (!replog.testingComplete){
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

            /*
             `testingHasFinished` returns YES when the bundle connection AND testmanagerd
             connection are finished with the connection (presumably at end of test or failure)
             */
            if ([testManager testingHasFinished]) {
                break;
            }
        }
        if (e) {
            ConsoleWriteErr(@"Error starting test: %@", e);
            return iOSReturnStatusCodeInternalError;
        }
    }
    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)uploadFile:(NSString *)filepath forApplication:(NSString *)bundleID overwrite:(BOOL)overwrite {

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:filepath]) {
        ConsoleWriteErr(@"File does not exist: %@", filepath);
        return iOSReturnStatusCodeInvalidArguments;
    }

    NSString *containerPath = [self containerPathForApplication:bundleID];
    if (!containerPath) {
        ConsoleWriteErr(@"Unable to find container path for app %@ on device %@", bundleID, [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSString *documentsDir = [containerPath stringByAppendingPathComponent:@"Documents"];
    NSString *filename = [filepath lastPathComponent];
    NSString *dest = [documentsDir stringByAppendingPathComponent:filename];
    NSError *e;

    if ([fm fileExistsAtPath:dest]) {
        if (!overwrite) {
            ConsoleWriteErr(@"'%@' already exists in the app container. Specify `-o true` to overwrite.", filename);
            return iOSReturnStatusCodeGenericFailure;
        } else {
            if (![fm removeItemAtPath:dest error:&e]) {
                ConsoleWriteErr(@"Unable to remove file at path %@: %@", dest, e);
                return iOSReturnStatusCodeGenericFailure;
            }
        }
    }

    if (![fm copyItemAtPath:filepath toPath:dest error:&e]) {
        ConsoleWriteErr(@"Error copying file %@ to data bundle: %@", filepath, e);
        return iOSReturnStatusCodeGenericFailure;
    }

    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)updateInstalledAppIfNecessary:(Application *)app {

    NSError *e;
    FBApplicationDescriptor *installed = [self.fbSimulator installedApplicationWithBundleID:app.bundleID error:&e];
    if (!installed || e) {
        ConsoleWriteErr(@"Error retrieving installed application %@: %@", app.bundleID, e);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSString *newPlistPath = [app.path stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *newPlist = [NSDictionary dictionaryWithContentsOfFile:newPlistPath];

    Application *installedApp = [self installedApp:installed.bundleID];
    NSDictionary *oldPlist = installedApp.infoPlist;

    if (!newPlist) {
        ConsoleWriteErr(@"Unable to locate Info.plist in app bundle: %@", app.path);
        return iOSReturnStatusCodeGenericFailure;
    }
    if (!oldPlist) {
        ConsoleWriteErr(@"Unable to locate Info.plist in app bundle: %@", installed.path);
        return iOSReturnStatusCodeGenericFailure;
    }

    if ([AppUtils appVersionIsDifferent:oldPlist newPlist:newPlist]) {
        ConsoleWriteErr(@"Installed version is different, attempting to update %@.", installed.bundleID);
        iOSReturnStatusCode ret = [self uninstallApp:app.bundleID];
        if (ret != iOSReturnStatusCodeEverythingOkay) {
            return ret;
        }

        return [self installApp:app shouldUpdate:YES];
    } else {
        DDLogInfo(@"Latest version of %@ is installed, not reinstalling.", installed.bundleID);
    }

    return iOSReturnStatusCodeEverythingOkay;
}

+ (FBApplicationDescriptor *)app:(NSString *)appPath {
    NSError *e;
    FBApplicationDescriptor *app = [FBApplicationDescriptor userApplicationWithPath:appPath
                                                                              error:&e];
    if (!app || e) {
        ConsoleWriteErr(@"Error creating SimulatorApplication for path %@: %@", appPath, e);
        return nil;
    }
    return app;
}

+ (FBApplicationLaunchConfiguration *)testRunnerLaunchConfig:(NSString *)testRunnerPath {
    FBApplicationDescriptor *application = [self app:testRunnerPath];

    return [FBApplicationLaunchConfiguration configurationWithApplication:application
                                                                arguments:@[]
                                                              environment:@{}
                                                                   output:[FBProcessOutputConfiguration defaultForDeviceManager]];
}

+ (BOOL)iOS_GTE_9:(NSString *)versionString {
    NSArray <NSString *> *components = [versionString componentsSeparatedByString:@" "];
    if (components.count < 2) {
        DDLogWarn(@"Unparseable version string: %@", versionString);
        return YES;
    }
    NSString *versionNumberString = components[1];
    float versionNumber = [versionNumberString floatValue];
    if (versionNumber < 9) {
        ConsoleWriteErr(@"The simulator you selected has %@ installed. \n\
%@ is not valid for testing. \n\
Tests can not be run on iOS less than 9.0",
              versionString,
              versionString);
        return NO;
    }
    DDLogInfo(@"%@ is valid for testing.", versionString);
    return YES;
}


+ (FBSimulator *)simulatorWithConfiguration:(FBSimulatorConfiguration *)configuration {
    NSError *error = nil;
    FBSimulator *simulator = [_control.pool allocateSimulatorWithConfiguration:configuration
                                                                           options:FBSimulatorAllocationOptionsReuse
                                                                             error:&error];
    if (error) {
        ConsoleWriteErr(@"Error obtaining simulator: %@", error);
    }
    return simulator;
}

#pragma mark - Test Reporter Methods

- (void)testManagerMediatorDidBeginExecutingTestPlan:(FBTestManagerAPIMediator *)mediator {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
                  testSuite:(NSString *)testSuite
                 didStartAt:(NSString *)startTime {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator testCaseDidFinishForTestClass:(NSString *)testClass method:(NSString *)method withStatus:(FBTestReportStatus)status duration:(NSTimeInterval)duration {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator testCaseDidFailForTestClass:(NSString *)testClass method:(NSString *)method withMessage:(NSString *)message file:(NSString *)file line:(NSUInteger)line {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
testBundleReadyWithProtocolVersion:(NSInteger)protocolVersion
             minimumVersion:(NSInteger)minimumVersion {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
testCaseDidStartForTestClass:(NSString *)testClass
                     method:(NSString *)method {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
        finishedWithSummary:(FBTestManagerResultSummary *)summary {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediatorDidFinishExecutingTestPlan:(FBTestManagerAPIMediator *)mediator {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    self.testingComplete = YES;
}

#pragma mark - FBControlCoreLogger
- (id<FBControlCoreLogger>)log:(NSString *)string {
    DDLogInfo(@"%@", string);
    return self;
}

- (id<FBControlCoreLogger>)logFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2) {
    va_list args;
    va_start(args, format);
    id str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    DDLogInfo(@"%@", str);
    return self;
}

- (id<FBControlCoreLogger>)info {
    return self;
}

- (id<FBControlCoreLogger>)debug {
    return self;
}

- (id<FBControlCoreLogger>)error {
    return self;
}

- (id<FBControlCoreLogger>)onQueue:(dispatch_queue_t)queue {
    return self;
}

- (id<FBControlCoreLogger>)withPrefix:(NSString *)prefix {
    return self;
}

- (NSString *)containerPathForApplication:(NSString *)bundleID {
    NSFileManager *fm = [NSFileManager defaultManager];

    NSString *appDataPath = [[[[[[[[[NSHomeDirectory()
                                     stringByAppendingPathComponent:@"Library"]
                                    stringByAppendingPathComponent:@"Developer"]
                                   stringByAppendingPathComponent:@"CoreSimulator"]
                                  stringByAppendingPathComponent:@"Devices"]
                                 stringByAppendingPathComponent:[self uuid]]
                                stringByAppendingPathComponent:@"data"]
                               stringByAppendingPathComponent:@"Containers"]
                              stringByAppendingPathComponent:@"Data"]
                             stringByAppendingPathComponent:@"Application"];
    
    NSArray *bundleFolders = [fm contentsOfDirectoryAtPath:appDataPath error:nil];

    for (id bundleFolder in bundleFolders) {
        NSString *bundleFolderPath = [appDataPath stringByAppendingPathComponent:bundleFolder];
        NSString *plistFile = [bundleFolderPath
                               stringByAppendingPathComponent:@".com.apple.mobile_container_manager.metadata.plist"];

        if ([fm fileExistsAtPath:plistFile]) {
            NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistFile];
            if ([plist[@"MCMMetadataIdentifier"] isEqualToString:bundleID]) {
                ConsoleWrite(@"%@", bundleFolderPath);
                return bundleFolderPath;
            }
        }
    }

    return nil;
}

@end
