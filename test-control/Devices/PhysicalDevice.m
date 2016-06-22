
#import "PhysicalDevice.h"
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import <FBControlCore/FBControlCore.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "ShellRunner.h"

@interface DVTAbstractiOSDevice : NSObject
- (id)applications;
@end

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
    NSString *fileName = [NSString stringWithFormat:@"%@_%@",
                          [[NSProcessInfo processInfo] globallyUniqueString], @"entitlements.plist"];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    
    if (![entsPlist writeToFile:filePath
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&e] || e) {
        NSLog(@"Unable to create entitlements file: %@", e);
        exit(1);
    }
    NSLog(@"Entitlements tmpfile %@:\n%@", filePath, entsPlist);
    
    NSTask *signTask = [NSTask new];
    signTask.launchPath = @"/usr/bin/codesign";
    signTask.arguments = @[@"-s", self.codesignIdentity, @"-f", bundlePath, @"--entitlements", filePath];
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

+ (Signer *)signer:(NSString *)codesignID {
    Signer *codesigner = [Signer new];
    codesigner.codesignIdentity = codesignID;
    return codesigner;
}

+ (FBiOSDeviceOperator *)opForID:(NSString *)deviceID codesigner:(id<FBCodesignProvider>)signer {
    NSError *err;
    FBiOSDeviceOperator *op = [FBiOSDeviceOperator operatorWithDeviceUDID:deviceID
                                                         codesignProvider:signer
                                                                    error:&err];
    
    [op waitForDeviceToBecomeAvailableWithError:&err];
    if (err) {
        NSLog(@"Device %@ isn't available: %@", deviceID, err);
        return nil;
    }
    return op;
}

#pragma mark - App Installation
+ (BOOL)installApp:(NSString *)pathToBundle
          deviceID:(NSString *)deviceID
        codesignID:(NSString *)codesignID {
    FBiOSDeviceOperator *op = [self opForID:deviceID codesigner:[self signer:codesignID]];
    if (!op) return NO;
    
    NSError *err;
    //Codesign
    FBProductBundle *app = [[[[FBProductBundleBuilder builderWithFileManager:[NSFileManager defaultManager]]
                              withBundlePath:pathToBundle]
                             withCodesignProvider:[self signer:codesignID]]
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

+ (BOOL)uninstallApp:(NSString *)bundleID deviceID:(NSString *)deviceID {
    FBiOSDeviceOperator *op = [self opForID:deviceID codesigner:[self signer:@""]];
    if (!op) return NO;
    
    NSError *err;
    if (![op isApplicationInstalledWithBundleID:bundleID error:&err]) {
        NSLog(@"Application %@ is not installed on %@", bundleID, deviceID);
        return NO;
    }
    
    if (err) {
        NSLog(@"Error checking if application %@ is installed: %@", bundleID, err);
        return NO;
    }
    
    if (![op cleanApplicationStateWithBundleIdentifier:bundleID error:&err] || err) {
        NSLog(@"Error uninstalling app %@: %@", bundleID, err);
    }
    return err == nil;
}

+ (int)appIsInstalled:(NSString *)bundleID deviceID:(NSString *)deviceID {
    FBiOSDeviceOperator *op = [self opForID:deviceID codesigner:[self signer:@""]];
    if (!op) return -1;
    
    NSError *err;
    BOOL installed = [op isApplicationInstalledWithBundleID:bundleID error:&err];
    if (err) {
        NSLog(@"Error checking if %@ is installed to %@: %@", bundleID, deviceID, err);
        return -1;
    }
    return installed ? 1 : 0;
}

+ (BOOL)clearAppData:(NSString *)bundleID
            deviceID:(NSString *)deviceID {
    if ([self appIsInstalled:bundleID deviceID:deviceID] != 1) {
        NSLog(@"Please ensure %@ is installed on %@ and try again.", bundleID, deviceID);
        return NO;
    }
    
    FBiOSDeviceOperator *op = [self opForID:deviceID codesigner:[self signer:@""]];
    if (!op) return NO;
    
    NSString *appDataFilename = [[NSString stringWithFormat:@"%@.xcappdata",
                                 [[NSProcessInfo processInfo] globallyUniqueString]]
                                 stringByAppendingPathComponent:@"AppData"];
    NSString *emptyDataBundle = [NSTemporaryDirectory() stringByAppendingString:appDataFilename];
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    NSError *err;
    if (![mgr createDirectoryAtPath:emptyDataBundle withIntermediateDirectories:YES
                    attributes:nil
                              error:&err] || err) {
        NSLog(@"Unable to create file %@ at path %@: %@", appDataFilename, emptyDataBundle, err);
        return NO;
    }
    
    
    
    if (![op uploadApplicationDataAtPath:emptyDataBundle bundleID:bundleID error:&err]) {
        NSLog(@"Error clearing data for %@ on device %@: %@", bundleID, deviceID, err);
        return NO;
    }
    
    return YES;
}

@end
