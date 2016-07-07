
#import "Simulator.h"

#import <FBSimulatorControl/FBSimulatorControl.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import "ShellRunner.h"

@implementation Simulator
static FBSimulatorControl *_control;

+ (iOSReturnStatusCode)startTestOnDevice:(NSString *)deviceID
                          testRunnerPath:(NSString *)testRunnerPath
                          testBundlePath:(NSString *)testBundlePath
                        codesignIdentity:(NSString *)codesignIdentity
                               keepAlive:(BOOL)keepAlive {
    if (![TestParameters isSimulatorID:deviceID]) {
        NSLog(@"'%@' is not a valid sim ID", deviceID);
        return iOSReturnStatusCodeInvalidArguments;
    }
    
    NSError *e;
    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (!simulator) { return iOSReturnStatusCodeDeviceNotFound; }
    
    FBSimulatorApplication *app = [self app:testRunnerPath];
    
    [[simulator.interact installApplication:app] perform:&e];
    if (e) {
        NSLog(@"Unable to install application %@ to %@: %@", app.bundleID, deviceID, e);
        return iOSReturnStatusCodeGenericFailure;
    }
    
    FBApplicationLaunchConfiguration *launch = [FBApplicationLaunchConfiguration configurationWithApplication:app
                                                                                                    arguments:@[]
                                                                                                  environment:@{}
                                                                                                      options:FBProcessLaunchOptionsWriteStdout];
    [[simulator.interact startTestRunnerLaunchConfiguration:launch testBundlePath:testBundlePath] perform:&e];
    
    if (e) {
        NSLog(@"Error starting test runner: %@", e);
        return iOSReturnStatusCodeInternalError;
    } else if (keepAlive) {
        [[NSRunLoop mainRunLoop] run];
    }
    return iOSReturnStatusCodeEverythingOkay;
}

+ (FBSimulatorApplication *)app:(NSString *)appPath {
    NSError *e;
    FBSimulatorApplication *app = [FBSimulatorApplication applicationWithPath:appPath error:&e];
    if (!app || e) {
        NSLog(@"Error creating SimulatorApplication for path %@: %@", appPath, e);
        return nil;
    }
    return app;
}

+ (FBApplicationLaunchConfiguration *)testRunnerLaunchConfig:(NSString *)testRunnerPath {
    FBSimulatorApplication *application = [self app:testRunnerPath];
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
    FBSimulatorApplication *app = [self app:pathToBundle];
    [[simulator.interact installApplication:app] perform:&e];
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
