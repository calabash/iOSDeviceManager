
#import "Simulator.h"

#import <FBSimulatorControl/FBSimulatorControl.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import "ShellRunner.h"
#import "AppUtils.h"
#import "Codesigner.h"

@implementation Simulator
static FBSimulatorControl *_control;

+ (NSDictionary *)infoPlistForInstalledBundleID:(NSString *)bundleID
                                       deviceID:(NSString *)deviceID {
    return [self infoPlistForInstalledBundleID:bundleID
                                        device:[self simulatorWithDeviceID:deviceID]];
}

+ (NSDictionary *)infoPlistForInstalledBundleID:(NSString *)bundleID device:(FBSimulator *)device {
    FBApplicationDescriptor *installed = [device installedApplicationWithBundleID:bundleID error:nil];
    if (!installed) {
        return nil;
    }
    NSString *plistPath = [installed.path stringByAppendingPathComponent:@"Info.plist"];
    return [NSDictionary dictionaryWithContentsOfFile:plistPath];
}

+ (iOSReturnStatusCode)updateInstalledAppIfNecessary:(NSString *)bundlePath
                                              device:(FBSimulator *)device {
    NSError *e;
    FBProductBundle *newApp = [[[FBProductBundleBuilder builder]
                                withBundlePath:bundlePath]
                               buildWithError:&e];

    if (e) {
        NSLog(@"Unable to create product bundle for application at %@: %@", bundlePath, e);
        return iOSReturnStatusCodeGenericFailure;
    }

    FBApplicationDescriptor *installed = [device installedApplicationWithBundleID:newApp.bundleID error:&e];
    if (!installed || e) {
        NSLog(@"Error retrieving installed application %@: %@", newApp.bundleID, e);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSString *newPlistPath = [bundlePath stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *newPlist = [NSDictionary dictionaryWithContentsOfFile:newPlistPath];

    NSDictionary *oldPlist = [self infoPlistForInstalledBundleID:newApp.bundleID
                                                          device:device];

    if (!newPlist) {
        NSLog(@"Unable to locate Info.plist in app bundle: %@", bundlePath);
        return iOSReturnStatusCodeGenericFailure;
    }
    if (!oldPlist) {
        NSLog(@"Unable to locate Info.plist in app bundle: %@", installed.path);
        return iOSReturnStatusCodeGenericFailure;
    }

    if ([AppUtils appVersionIsDifferent:oldPlist newPlist:newPlist]) {
        NSLog(@"Installed version is different, attempting to update %@.", installed.bundleID);
        iOSReturnStatusCode ret = [self uninstallApp:newApp.bundleID deviceID:device.udid];
        if (ret != iOSReturnStatusCodeEverythingOkay) {
            return ret;
        }
        return [self installApp:bundlePath
                       deviceID:device.udid
                      updateApp:YES
                     codesignID:@""];
    } else {
        NSLog(@"Latest version of %@ is installed, not reinstalling.", installed.bundleID);
    }

    return iOSReturnStatusCodeEverythingOkay;
}

+ (iOSReturnStatusCode)startTestOnDevice:(NSString *)deviceID
                               sessionID:(NSUUID *)sessionID
                          runnerBundleID:(NSString *)runnerBundleID
                               keepAlive:(BOOL)keepAlive {
    if (![TestParameters isSimulatorID:deviceID]) {
        NSLog(@"'%@' is not a valid sim ID", deviceID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    NSError *e;
    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (!simulator) { return iOSReturnStatusCodeDeviceNotFound; }

    if (simulator.state == FBSimulatorStateShutdown ) {
        [[simulator.interact bootSimulator] perform:&e];
        NSLog(@"Sim is dead, booting.");
        if (e) {
            NSLog(@"Error booting simulator %@ for test: %@", deviceID, e);
            return iOSReturnStatusCodeInternalError;
        }
    }

    if ([self appIsInstalled:runnerBundleID deviceID:deviceID] == iOSReturnStatusCodeFalse) {
        NSLog(@"TestRunner %@ must be installed before you can run a test.", runnerBundleID);
        return iOSReturnStatusCodeGenericFailure;
    }

    Simulator *replog = [Simulator new];
    id<FBDeviceOperator> op = [FBSimulatorControlOperator operatorWithSimulator:simulator];
    [XCTestBootstrapFrameworkLoader loadPrivateFrameworksOrAbort];
    FBTestManager *testManager = [FBXCTestRunStrategy startTestManagerForDeviceOperator:op
                                                                         runnerBundleID:runnerBundleID
                                                                              sessionID:sessionID
                                                                         withAttributes:[FBTestRunnerConfigurationBuilder defaultBuildAttributes]
                                                                            environment:[FBTestRunnerConfigurationBuilder defaultBuildEnvironment]
                                                                               reporter:replog
                                                                                 logger:replog
                                                                                  error:&e];

    if (e) {
        NSLog(@"Error starting test runner: %@", e);
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
            NSLog(@"Error starting test: %@", e);
            return iOSReturnStatusCodeInternalError;
        }
    }
    return iOSReturnStatusCodeEverythingOkay;
}

+ (FBApplicationDescriptor *)app:(NSString *)appPath {
    NSError *e;
    FBApplicationDescriptor *app = [FBApplicationDescriptor applicationWithPath:appPath error:&e];
    if (!app || e) {
        NSLog(@"Error creating SimulatorApplication for path %@: %@", appPath, e);
        return nil;
    }
    return app;
}

+ (FBApplicationLaunchConfiguration *)testRunnerLaunchConfig:(NSString *)testRunnerPath {
    FBApplicationDescriptor *application = [self app:testRunnerPath];
    return [FBApplicationLaunchConfiguration configurationWithApplication:application
                                                                arguments:@[]
                                                              environment:@{}
                                                                  options:0];
}

+ (BOOL)iOS_GTE_9:(NSString *)versionString {
    NSArray <NSString *> *components = [versionString componentsSeparatedByString:@" "];
    if (components.count < 2) {
        NSLog(@"WARNING: Unparseable version string: %@", versionString);
        return YES;
    }
    NSString *versionNumberString = components[1];
    float versionNumber = [versionNumberString floatValue];
    if (versionNumber < 9) {
        NSLog(@"The simulator you selected has %@ installed. \n\
%@ is not valid for testing. \n\
Tests can not be run on iOS less than 9.0",
              versionString,
              versionString);
        return NO;
    }
    NSLog(@"%@ is valid for testing.", versionString);
    return YES;
}

+ (FBSimulator *)simulatorWithDeviceID:(NSString *)deviceID {
    FBSimulatorSet *sims = [self control].set;
    if (!sims) { return nil; }

    FBiOSTargetQuery *query = [FBiOSTargetQuery udids:@[deviceID]];
    NSArray <FBSimulator *> *results = [sims query:query];
    if (results.count == 0) {
        NSLog(@"No simulators found for ID %@", deviceID);
        return nil;
    }
    FBSimulator *sim = results[0];
    return sim;
}

+ (FBSimulator *)simulatorWithConfiguration:(FBSimulatorConfiguration *)configuration {
    NSError *error = nil;
    FBSimulator *simulator = [self.control.pool allocateSimulatorWithConfiguration:configuration
                                                                           options:FBSimulatorAllocationOptionsReuse
                                                                             error:&error];
    if (error) {
        NSLog(@"Error obtaining simulator: %@", error);
    }
    return simulator;
}

+ (FBSimulatorControl *)control {
    return _control;
}

+ (void)initialize {
    FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration
                                                      configurationWithDeviceSetPath:nil
                                                      options:FBSimulatorManagementOptionsIgnoreSpuriousKillFail];

    NSError *error;
    _control = [FBSimulatorControl withConfiguration:configuration error:&error];
    if (error) {
        NSLog(@"Error creating FBSimulatorControl: %@", error);
        abort();
    }
}


#pragma mark - Test Reporter Methods

- (void)testManagerMediatorDidBeginExecutingTestPlan:(FBTestManagerAPIMediator *)mediator {
    NSLog(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
                  testSuite:(NSString *)testSuite
                 didStartAt:(NSString *)startTime {
    NSLog(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator testCaseDidFinishForTestClass:(NSString *)testClass method:(NSString *)method withStatus:(FBTestReportStatus)status duration:(NSTimeInterval)duration {
    NSLog(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator testCaseDidFailForTestClass:(NSString *)testClass method:(NSString *)method withMessage:(NSString *)message file:(NSString *)file line:(NSUInteger)line {
    NSLog(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
testBundleReadyWithProtocolVersion:(NSInteger)protocolVersion
             minimumVersion:(NSInteger)minimumVersion {
    NSLog(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
testCaseDidStartForTestClass:(NSString *)testClass
                     method:(NSString *)method {
    NSLog(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
        finishedWithSummary:(FBTestManagerResultSummary *)summary {
    NSLog(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediatorDidFinishExecutingTestPlan:(FBTestManagerAPIMediator *)mediator {
    NSLog(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    self.testingComplete = YES;
}

#pragma mark - FBControlCoreLogger
- (id<FBControlCoreLogger>)log:(NSString *)string {
    NSLog(@"%@", string);
    return self;
}

- (id<FBControlCoreLogger>)logFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2) {
    va_list args;
    va_start(args, format);
    id str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSLog(@"%@", str);
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

+ (iOSReturnStatusCode)installApp:(NSString *)pathToBundle
                         deviceID:(NSString *)deviceID
                        updateApp:(BOOL)updateApp
                       codesignID:(NSString *)codesignID {
    if (![TestParameters isSimulatorID:deviceID]) {
        NSLog(@"'%@' is not a valid sim ID", deviceID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    NSError *e;
    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (!simulator) { return iOSReturnStatusCodeDeviceNotFound; }

    if (simulator.state == FBSimulatorStateShutdown ||
        simulator.state == FBSimulatorStateShuttingDown) {
        NSLog(@"Simulator %@ is dead. Must launch sim before installing an app.", deviceID);
        return iOSReturnStatusCodeGenericFailure;
    }
    FBApplicationDescriptor *app = [self app:pathToBundle];

    Codesigner *signer = [[Codesigner alloc] initAdHocWithDeviceUDID:deviceID];

    if (![signer validateSignatureAtBundlePath:pathToBundle]) {
        NSError *signError;

        [signer signBundleAtPath:pathToBundle
                           error:&signError];

        if (signError) {
            NSLog(@"Error resigning sim bundle");
            NSLog(@"  Path to bundle: %@", pathToBundle);
            NSLog(@"  Device UDID: %@", deviceID);
            NSLog(@"  ERROR: %@", signError);
            return iOSReturnStatusCodeGenericFailure;
        }
    }

    if ([self appIsInstalled:app.bundleID deviceID:deviceID] == iOSReturnStatusCodeFalse) {
        [[simulator.interact installApplication:app] perform:&e];
    } else if (updateApp) {
        iOSReturnStatusCode ret = [self updateInstalledAppIfNecessary:pathToBundle device:simulator];
        if (ret != iOSReturnStatusCodeEverythingOkay) {
            return ret;
        }
    }

    if (e) {
        NSLog(@"Error installing %@ to %@: %@", app.bundleID, deviceID, e);
        return iOSReturnStatusCodeInternalError;
    } else {
        NSLog(@"Installed %@ to %@", app.bundleID, deviceID);
    }
    return iOSReturnStatusCodeEverythingOkay;

}

+ (iOSReturnStatusCode)launchSimulator:(NSString *)simID {
    if (![TestParameters isSimulatorID:simID]) {
        NSLog(@"'%@' is not a valid sim ID", simID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    FBSimulator *simulator = [self simulatorWithDeviceID:simID];
    if (simulator == nil) {
        NSLog(@"");
    }
    NSError *e;
    if (simulator.state == FBSimulatorStateShutdown ||
        simulator.state == FBSimulatorStateShuttingDown) {
        NSLog(@"Sim is dead, booting...");

        FBSimulatorLaunchConfiguration *launchConfig = [FBSimulatorLaunchConfiguration withOptions:
                                                        FBSimulatorLaunchOptionsConnectBridge];

        [[simulator.interact bootSimulator:launchConfig] perform:&e];
        if (e) {
            NSLog(@"Failed to boot sim: %@", e);
            return iOSReturnStatusCodeInternalError;
        }
    }
    return simulator != nil ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeInternalError;
}

+ (iOSReturnStatusCode)killSimulator:(NSString *)simID {
    if (![TestParameters isSimulatorID:simID]) {
        NSLog(@"'%@' is not a valid sim ID", simID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    FBSimulator *simulator = [self simulatorWithDeviceID:simID];
    if (simulator == nil) {
        NSLog(@"No such simulator exists!");
        return iOSReturnStatusCodeDeviceNotFound;
    }
    if (simulator.state == FBSimulatorStateShutdown) {
        NSLog(@"Simulator %@ is already shut down", simID);
        return iOSReturnStatusCodeEverythingOkay;
    } else if (simulator.state == FBSimulatorStateShuttingDown) {
        NSLog(@"Simulator %@ is already shutting down", simID);
        return iOSReturnStatusCodeEverythingOkay;
    }

    NSError *e;
    [[simulator.interact shutdownSimulator] perform:&e];

    if (e ) {
        NSLog(@"Error shutting down sim %@: %@", simID, e);
    }

    return e == nil ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeInternalError;
}

+ (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID
                           deviceID:(NSString *)deviceID {
    if (![TestParameters isSimulatorID:deviceID]) {
        NSLog(@"'%@' is not a valid sim ID", deviceID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (simulator == nil) {
        NSLog(@"No such simulator exists!");
        return iOSReturnStatusCodeDeviceNotFound;
    }
    if (simulator.state == FBSimulatorStateShutdown ||
        simulator.state == FBSimulatorStateShuttingDown) {
        NSLog(@"Simulator %@ is dead. Must launch before uninstalling apps.", deviceID);
        return iOSReturnStatusCodeGenericFailure;
    }

    if ([self appIsInstalled:bundleID deviceID:deviceID] == iOSReturnStatusCodeFalse) {
        NSLog(@"App %@ is not installed on %@", bundleID, deviceID);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    [[simulator.interact uninstallApplicationWithBundleID:bundleID] perform:&e];
    if (e) {
        NSLog(@"Error uninstalling app: %@", e);
    }
    return e == nil ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeInternalError;
}

+ (iOSReturnStatusCode)appIsInstalled:(NSString *)bundleID
                             deviceID:(NSString *)deviceID {
    if (![TestParameters isSimulatorID:deviceID]) {
        NSLog(@"'%@' is not a valid sim ID", deviceID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (simulator == nil) {
        NSLog(@"No such simulator exists!");
        return iOSReturnStatusCodeDeviceNotFound;
    }

    NSError *e;
    BOOL installed = [simulator isApplicationInstalledWithBundleID:bundleID error:&e];

    return installed ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeFalse;
}

+ (iOSReturnStatusCode)setLocation:(NSString *)deviceID
                               lat:(double)lat
                               lng:(double)lng {
    if (![TestParameters isSimulatorID:deviceID]) {
        NSLog(@"'%@' is not a valid sim ID", deviceID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (simulator == nil) {
        NSLog(@"No such simulator exists!");
        return iOSReturnStatusCodeDeviceNotFound;
    }

    if (simulator.state == FBSimulatorStateShutdown ||
        simulator.state == FBSimulatorStateShuttingDown) {
        NSLog(@"Sim is dead! Must boot first");
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    FBSimulatorBridge *bridge = [FBSimulatorBridge bridgeForSimulator:simulator error:&e];
    if (e || !bridge) {
        NSLog(@"Unable to fetch simulator bridge: %@", e);
        return iOSReturnStatusCodeInternalError;
    }

    [bridge setLocationWithLatitude:lat longitude:lng];

    return iOSReturnStatusCodeEverythingOkay;
}

+ (NSDictionary *)lastLaunchServicesMapForSim:(NSString *)deviceID {
    NSString *lastLaunchServicesPlistPath = [[[[[[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
                                                    stringByAppendingPathComponent:@"Developer"]
                                                   stringByAppendingPathComponent:@"CoreSimulator"]
                                                  stringByAppendingPathComponent:@"Devices"]
                                                 stringByAppendingPathComponent:deviceID]
                                                stringByAppendingPathComponent:@"data"]
                                               stringByAppendingPathComponent:@"Library"]
                                              stringByAppendingPathComponent:@"MobileInstallation"]
                                             stringByAppendingPathComponent:@"LastLaunchServicesMap.plist"];
    return [NSDictionary dictionaryWithContentsOfFile:lastLaunchServicesPlistPath];
}


@end
