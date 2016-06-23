
#import "Simulator.h"

#import <FBSimulatorControl/FBSimulatorControl.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import <FBDeviceControl/FBDeviceControl.h>

@implementation Simulator
static FBSimulatorControl *_control;

+ (BOOL)startTest:(SimulatorTestParameters *)params {
    NSAssert(params.deviceType == kDeviceTypeSimulator,
             @"Can not run a Simulator test with an instance of %@",
             NSStringFromClass(params.class));
    NSError *e;
    FBSimulator *simulator = [self simulatorWithDeviceID:params.deviceID];
    if (!simulator) { return NO; }
    
    if (![self iOS_GTE_9:simulator.configuration.osVersionString]) {
        return NO;
    }
    
    if (![self launchSimulator:params.deviceID]) {
        return NO;
    }
   
    FBSimulatorApplication *app = [self app:params.testRunnerPath];
    [[[simulator.interact installApplication:app] startTestRunnerLaunchConfiguration:[self testRunnerLaunchConfig:params.testRunnerPath]
                                                                      testBundlePath:params.testBundlePath
                                                                            reporter:[self new]] perform:&e];
    
    if (e) {
        NSLog(@"Error starting test runner: %@", e);
        return NO;
    } else {
        [[NSRunLoop mainRunLoop] run];
    }
    return YES;
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
        NSLog(@"Unparseable version string: %@", versionString);
        return NO;
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
    if (![TestParameters isSimulatorID:deviceID]) {
        NSLog(@"'%@' is not a valid sim ID", deviceID);
        return nil;
    }
    
    NSError *e;
    FBSimulatorControlConfiguration *controlConfig = [FBSimulatorControlConfiguration configurationWithDeviceSetPath:nil
                                                                                                             options:0];
    FBSimulatorSet *sims = [FBSimulatorSet setWithConfiguration:controlConfig
                                                        control:self.control
                                                         logger:[self new]
                                                          error:&e];
    if (e) {
        NSLog(@"Error fetching simulator set: %@", e);
    }
    FBSimulatorQuery *query = [[FBSimulatorQuery udids:@[deviceID]]
                               states:[FBCollectionOperations indecesFromArray:@[
                                                                                 @(FBSimulatorStateBooted),
                                                                                 @(FBSimulatorStateBooting),
                                                                                 @(FBSimulatorStateShutdown)
                                                                                 ]]];
    NSArray <FBSimulator *> *results = [query perform:sims];
    if (results.count == 0) {
        NSLog(@"No simulators found for ID %@", deviceID);
        return nil;
    }
    FBSimulator *sim = results[0];
    NSLog(@"Found simulator match: %@", sim);
    
    return sim;
}

+ (FBSimulator *)simulatorWithConfiguration:(FBSimulatorConfiguration *)configuration
{
    NSError *error = nil;
    FBSimulator *simulator = [self.control.pool allocateSimulatorWithConfiguration:configuration
                                                                           options:FBSimulatorAllocationOptionsReuse
                                                                             error:&error];
    if (error) {
        NSLog(@"Error obtaining simulator: %@", error);
    }
    return simulator;
}

+ (FBSimulatorControl *)control
{
    if (!_control) {
        FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration
                                                          configurationWithDeviceSetPath:nil
                                                          options:FBSimulatorManagementOptionsIgnoreSpuriousKillFail];
        
        NSError *error;
        FBSimulatorControl *control = [FBSimulatorControl withConfiguration:configuration error:&error];
        _control = control;
    }
    return _control;
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

+ (BOOL)installApp:(NSString *)pathToBundle
          deviceID:(NSString *)deviceID
        codesignID:(NSString *)codesignID {
    NSError *e;
    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (!simulator) { return NO; }
    
    if (simulator.state == FBSimulatorStateShutdown ||
        simulator.state == FBSimulatorStateShuttingDown) {
        NSLog(@"Simulator %@ is dead. Must launch sim before installing an app.", deviceID);
        return NO;
    }
    FBSimulatorApplication *app = [self app:pathToBundle];
    [[simulator.interact installApplication:app] perform:&e];
    if (e) {
        NSLog(@"Error installing %@ to %@: %@", app.bundleID, deviceID, e);
        return NO;
    } else {
        NSLog(@"Installed %@ to %@", app.bundleID, deviceID);
    }
    return YES;
    
}

+ (BOOL)launchSimulator:(NSString *)simID {
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
            return NO;
        }
    }
    return simulator != nil;
}

+ (BOOL)killSimulator:(NSString *)simID {
    FBSimulator *simulator = [self simulatorWithDeviceID:simID];
    if (simulator == nil) {
        NSLog(@"No such simulator exists!");
        return NO;
    }
    if (simulator.state == FBSimulatorStateShutdown) {
        NSLog(@"Simulator %@ is already shut down", simID);
        return YES;
    } else if (simulator.state == FBSimulatorStateShuttingDown) {
        NSLog(@"Simulator %@ is already shutting down", simID);
        return YES;
    }
    
    FBSimulatorControlConfiguration *controlConfig = [FBSimulatorControlConfiguration configurationWithDeviceSetPath:nil
                                                                                                             options:0];
    
    FBSimulatorTerminationStrategy *terminator = [FBSimulatorTerminationStrategy withConfiguration:controlConfig
                                                                                    processFetcher:[FBProcessFetcher new]
                                                                                            logger:nil];
    
    NSError *e;
    [terminator killSimulators:@[simulator] error:&e];

    if (e) {
        NSLog(@"Error shutting down sim %@: %@", simID, e);
    }
    
    return e == nil;
}

+ (BOOL)uninstallApp:(NSString *)bundleID
            deviceID:(NSString *)deviceID {
    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (simulator == nil) {
        NSLog(@"No such simulator exists!");
        return NO;
    }
    if (simulator.state == FBSimulatorStateShutdown ||
        simulator.state == FBSimulatorStateShuttingDown) {
        NSLog(@"Simulator %@ is dead. Must launch before uninstalling apps.", deviceID);
        return NO;
    }
    
    if (![self appIsInstalled:bundleID deviceID:deviceID]) {
        NSLog(@"App %@ is not installed on %@", bundleID, deviceID);
        return NO;
    }
    
    NSError *e;
    [[simulator.interact uninstallApplicationWithBundleID:bundleID] perform:&e];
    if (e) {
        NSLog(@"Error uninstalling app: %@", e);
    }
    return e == nil;
}

+ (int)appIsInstalled:(NSString *)bundleID deviceID:(NSString *)deviceID {
    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (simulator == nil) {
        NSLog(@"No such simulator exists!");
        return -1;
    }
    
    NSError *e;
    FBSimulatorControlOperator *op = [FBSimulatorControlOperator operatorWithSimulator:simulator];
    BOOL installed = [op isApplicationInstalledWithBundleID:bundleID error:&e];
    if (e) {
        NSLog(@"Error checing if app %@ is installed on %@: %@", bundleID, deviceID, e);
        return NO;
    }
    //FIXME: error is non-nil if the app isn't found...
    //Maybe this isn't a problem, since an error shouldn't occur if we have a valid sim.
    
    return installed ? 1 : 0;
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
