
#import "PhysicalDevice.h"
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import <FBControlCore/FBControlCore.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "ShellRunner.h"

@interface Signer : NSObject  <FBCodesignProvider>
@property (nonatomic, strong) NSString *codesignIdentity;
@end

@implementation Signer

- (BOOL)signBundleAtPath:(NSString *)bundlePath {
    NSAssert(self.codesignIdentity != nil, @"Can not have a codesign command without an identity name");
    NSArray<NSString *> *ents = [ShellRunner shell:@"/usr/bin/xcrun"
                                              args:@[@"codesign",
                                                     @"-d",
                                                     @"--entitlements",
                                                     @":-",
                                                     bundlePath]];
    NSString *entsPlist = [ents componentsJoinedByString:@"\n"];
    NSError *e;
    if (![entsPlist writeToFile:@"/Users/chrisf/entitlements.plist"
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&e] || e) {
        NSLog(@"Unable to create entitlements file: %@", e);
        exit(1);
    }
    NSLog(@"Entitlements:\n%@", entsPlist);
    
    NSTask *signTask = [NSTask new];
    signTask.launchPath = @"/usr/bin/codesign";
    signTask.arguments = @[@"-s", self.codesignIdentity, @"-f", bundlePath, @"--entitlements", @"/Users/chrisf/entitlements.plist"];
    [signTask launch];
    [signTask waitUntilExit];
    return (signTask.terminationStatus == 0);
}

@end

@implementation PhysicalDevice
+ (BOOL)startTest:(DeviceTestParameters *)params {
    NSAssert(params.deviceType == kDeviceTypeDevice,
             @"Can not run a Device test with an instance of %@",
             NSStringFromClass(params.class));
    
    FBCodeSignCommand *codesigner = [FBCodeSignCommand codeSignCommandWithIdentityName:params.codesignIdentity];
    
    FBDeviceTestPreparationStrategy *testPrepareStrategy =
    [FBDeviceTestPreparationStrategy strategyWithTestRunnerApplicationPath:params.testRunnerPath
                                                       applicationDataPath:params.applicationDataPath
                                                            testBundlePath:params.testBundlePath
                                                    pathToXcodePlatformDir:params.pathToXcodePlatformDir
                                                          workingDirectory:params.workingDirectory];
    
    NSError *err;
    FBiOSDeviceOperator *op = [FBiOSDeviceOperator operatorWithDeviceUDID:params.deviceID
                                                         codesignProvider:codesigner
                                                                    error:&err];
    
    if (err) {
        NSLog(@"Error creating device operator: %@", err);
        return NO;
    }
    id reporterLogger = [self new];
    FBXCTestRunStrategy *testRunStrategy = [FBXCTestRunStrategy strategyWithDeviceOperator:op
                                                                       testPrepareStrategy:testPrepareStrategy
                                                                                  reporter:reporterLogger
                                                                                    logger:reporterLogger];
    NSError *innerError = nil;
    [testRunStrategy startTestManagerWithAttributes:@[] environment:@{} error:&innerError];
    
    if (!innerError) {
        [[NSRunLoop mainRunLoop] run];
    } else {
        NSLog(@"Err: %@", innerError);
        return NO;
    }
    return YES;
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

#pragma mark - App Installation
+ (BOOL)installApp:(NSString *)pathToBundle
          deviceID:(NSString *)deviceID
        codesignID:(NSString *)codesignID {
    
    NSError *err;
    Signer *codesigner = [Signer new];
    codesigner.codesignIdentity = codesignID;
    
    FBiOSDeviceOperator *op = [FBiOSDeviceOperator operatorWithDeviceUDID:deviceID
                                                         codesignProvider:codesigner
                                                                    error:&err];
    
    if (err) {
        NSLog(@"Error creating device operator: %@", err);
        return NO;
    }
    
    //Codesign
    FBProductBundle *app = [[[[FBProductBundleBuilder builderWithFileManager:[NSFileManager defaultManager]]
                              withBundlePath:pathToBundle]
                             withCodesignProvider:codesigner]
                            build];
    
    if ([op isApplicationInstalledWithBundleID:app.bundleID error:&err]) {
        NSLog(@"Application '%@' is already installed.", app.bundleID);
        return NO;
    }
    
    if (err) {
        NSLog(@"Error checking if app {%@} is installed. %@", app.bundleID, err);
        return NO;
    }
    
    if (![op installApplicationWithPath:pathToBundle error:&err] || err) {
        NSLog(@"Error installing application: %@", err);
        return NO;
    }
    
    return YES;
}
@end
