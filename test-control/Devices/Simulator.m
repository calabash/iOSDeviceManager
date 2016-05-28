
#import "Simulator.h"

#import <FBSimulatorControl/FBSimulatorControl.h>
#import <XCTestBootstrap/XCTestBootstrap.h>

@implementation Simulator
static FBSimulatorControl *_control;

+ (BOOL)startTest:(SimulatorTestParameters *)params {
    NSAssert(params.deviceType == kDeviceTypeSimulator,
             @"Can not run a Simulator test with an instance of %@",
             NSStringFromClass(params.class));
    NSError *e;
    FBSimulator *simulator = [self simulatorWithDeviceID:params.deviceID];
    if (!simulator) { return NO; }
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

+ (FBSimulator *)simulatorWithDeviceID:(NSString *)deviceID {
    NSError *e;
    FBSimulatorControlConfiguration *controlConfig = [FBSimulatorControlConfiguration configurationWithDeviceSetPath:nil
                                                                                                             options:0];
    FBSimulatorSet *sims = [FBSimulatorSet setWithConfiguration:controlConfig
                                                        control:self.control
                                                         logger:nil
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
    if (sim.state == FBSimulatorStateShutdown) {
        NSLog(@"Sim is dead, booting...");
        [[sim.interact bootSimulator:FBSimulatorLaunchConfiguration.defaultConfiguration] perform:&e];
        if (e) {
            NSLog(@"Failed to boot sim: %@", e);
            return nil;
        }
    }
    
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
                                                          options:FBSimulatorManagementOptionsKillSpuriousSimulatorsOnFirstStart | FBSimulatorManagementOptionsIgnoreSpuriousKillFail];
        
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

//
//+ (void)startTest {
//    NSError *error = nil;
//    FBSimulator *simulator = [self.control.pool allocateSimulatorWithConfiguration:FBSimulatorConfiguration.iPhone6s
//                                                                           options:FBSimulatorAllocationOptionsReuse | FBSimulatorAllocationOptionsCreate | FBSimulatorAllocationOptionsEraseOnAllocate
//                                                                             error:&error];
//    
//    NSString *testBundlePath = @"/Users/chrisf/calabash-xcuitest-server/Products/app/DeviceAgent/CBX-Runner.app/PlugIns/CBX.xctest";
//    NSString *bundleID = @"com.apple.test.CBX-Runner";
//    
//    FBSimulatorTestPreparationStrategy *testPrepareStrategy =
//    [FBSimulatorTestPreparationStrategy strategyWithTestRunnerBundleID:bundleID
//                                                        testBundlePath:testBundlePath
//                                                      workingDirectory:@"/Users/chrisf"
//     ];
//    
//    FBSimulatorApplication *app = [FBSimulatorApplication applicationWithPath:@"/Users/chrisf/calabash-xcuitest-server/Products/app/DeviceAgent/CBX-Runner.app" error:&error];
//    FBApplicationLaunchConfiguration *conf = [FBApplicationLaunchConfiguration configurationWithApplication:app arguments:@[] environment:@{} options:FBProcessLaunchOptionsWriteStdout];
//    [simulator.interact installApplication:app];
//    
//    [simulator.interact launchApplication:conf];
//    
////    FBSimulatorControlOperator *operator = [FBSimulatorControlOperator operatorWithSimulator:simulator];
////    FBXCTestRunStrategy *testRunStrategy = [FBXCTestRunStrategy strategyWithDeviceOperator:operator
////                                                                       testPrepareStrategy:testPrepareStrategy
////                                                                                  reporter:nil
////                                                                                    logger:simulator.logger];
////    NSError *innerError = nil;
////    FBTestManager *testManager = [testRunStrategy startTestManagerWithAttributes:@[]
////                                                                     environment:@{}
////                                                                           error:&innerError];
//    [[NSRunLoop mainRunLoop] run];
//}
@end
