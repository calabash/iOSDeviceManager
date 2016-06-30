
#import "PhysicalDevice.h"
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import <FBControlCore/FBControlCore.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "ShellRunner.h"
#import "Codesigner.h"

@interface DVTAbstractiOSDevice : NSObject
- (id)applications;
@end



@implementation PhysicalDevice
+ (NSString *)applicationDataPath {
    return nil;
}

+ (NSString *)pathToXcodePlatformDir {
    return nil;
}

+ (NSString *)workingDirectory {
    return nil;
}

+ (iOSReturnStatusCode)startTestOnDevice:(NSString *)deviceID
                          testRunnerPath:(NSString *)testRunnerPath
                          testBundlePath:(NSString *)testBundlePath
                        codesignIdentity:(NSString *)codesignIdentity {
    FBDeviceTestPreparationStrategy *testPrepareStrategy =
    [FBDeviceTestPreparationStrategy strategyWithTestRunnerApplicationPath:testRunnerPath
                                                       applicationDataPath:[self applicationDataPath]
                                                            testBundlePath:testBundlePath
                                                    pathToXcodePlatformDir:[self pathToXcodePlatformDir]
                                                          workingDirectory:[self workingDirectory]];
    
    FBDevice *device = [self deviceForID:deviceID codesigner:[self signer:codesignIdentity]];
    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }
    
    id reporterLogger = [self new];
    FBXCTestRunStrategy *testRunStrategy = [FBXCTestRunStrategy strategyWithDeviceOperator:device.deviceOperator
                                                                       testPrepareStrategy:testPrepareStrategy
                                                                                  reporter:reporterLogger
                                                                                    logger:reporterLogger];
    NSError *innerError = nil;
    [testRunStrategy startTestManagerWithAttributes:@[] environment:@{} error:&innerError];
    
    if (!innerError) {
        [[NSRunLoop mainRunLoop] run];
    } else {
        NSLog(@"Err: %@", innerError);
        return iOSReturnStatusCodeInternalError;
    }
    return iOSReturnStatusCodeEverythingOkay;
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

+ (Codesigner *)signer:(NSString *)codesignID {
    Codesigner *codesigner = [Codesigner new];
    codesigner.codesignIdentity = codesignID;
    return codesigner;
}

+ (FBDevice *)deviceForID:(NSString *)deviceID codesigner:(id<FBCodesignProvider>)signer {
    NSError *err;
    FBDevice *device = [[FBDeviceSet defaultSetWithLogger:nil
                                 error:&err]
            deviceWithUDID:deviceID];
    if (!device || err) {
        NSLog(@"Error getting device with ID %@: %@", deviceID, err);
        return nil;
    }
    device.deviceOperator.codesignProvider = signer;
    [device.deviceOperator waitForDeviceToBecomeAvailableWithError:&err];
    if (err) {
        NSLog(@"Error getting device with ID %@: %@", deviceID, err);
        return nil;
    }
    return device;
}

#pragma mark - App Installation
+ (iOSReturnStatusCode)installApp:(NSString *)pathToBundle
          deviceID:(NSString *)deviceID
        codesignID:(NSString *)codesignID {
    
    FBDevice *device = [self deviceForID:deviceID codesigner:[self signer:codesignID]];
    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }
    
    NSError *err;
    //Codesign
    FBProductBundle *app = [[[[FBProductBundleBuilder builderWithFileManager:[NSFileManager defaultManager]]
                              withBundlePath:pathToBundle]
                             withCodesignProvider:[self signer:codesignID]]
                            buildWithError:&err];
    
    if (err) {
        NSLog(@"Error creating product bundle for %@: %@", pathToBundle, err);
        return iOSReturnStatusCodeInternalError;
    }
    
    FBiOSDeviceOperator *op = device.deviceOperator;
    if ([op isApplicationInstalledWithBundleID:app.bundleID error:&err]) {
        NSLog(@"Application '%@' is already installed, attempting to override.", app.bundleID);
    }
    
    if (err) {
        NSLog(@"Error checking if app {%@} is installed. %@", app.bundleID, err);
        return iOSReturnStatusCodeInternalError;
    }
    
    if (![op installApplicationWithPath:pathToBundle error:&err] || err) {
        NSLog(@"Error installing application: %@", err);
        return iOSReturnStatusCodeInternalError;
    }
    
    return iOSReturnStatusCodeEverythingOkay;
}

+ (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID deviceID:(NSString *)deviceID {
    FBDevice *device = [self deviceForID:deviceID codesigner:nil];
    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }
    
    FBiOSDeviceOperator *op = device.deviceOperator;
    
    NSError *err;
    if (![op isApplicationInstalledWithBundleID:bundleID error:&err]) {
        NSLog(@"Application %@ is not installed on %@", bundleID, deviceID);
        return iOSReturnStatusCodeInternalError;
    }
    
    if (err) {
        NSLog(@"Error checking if application %@ is installed: %@", bundleID, err);
        return iOSReturnStatusCodeInternalError;
    }
    
    if (![op cleanApplicationStateWithBundleIdentifier:bundleID error:&err] || err) {
        NSLog(@"Error uninstalling app %@: %@", bundleID, err);
    }
    return err == nil ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeInternalError;
}

+ (iOSReturnStatusCode)appIsInstalled:(NSString *)bundleID deviceID:(NSString *)deviceID {
    FBDevice *device = [self deviceForID:deviceID codesigner:nil];
    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }
    
    NSError *err;
    BOOL installed = [device.deviceOperator isApplicationInstalledWithBundleID:bundleID
                                                                         error:&err];
    if (err) {
        NSLog(@"Error checking if %@ is installed to %@: %@", bundleID, deviceID, err);
        return iOSReturnStatusCodeInternalError;
    }
    return installed ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeFalse;
}

@end
