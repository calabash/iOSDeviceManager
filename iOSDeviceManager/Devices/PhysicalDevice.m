
#import "PhysicalDevice.h"
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import <FBControlCore/FBControlCore.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "ShellRunner.h"
#import "Codesigner.h"
#import "AppUtils.h"
#import "CodesignIdentity.h"

@protocol DVTApplication
- (NSDictionary *)plist;
@end

@interface DTDKRemoteDeviceToken : NSObject
- (_Bool)simulateLatitude:(NSNumber *)lat andLongitude:(NSNumber *)lng withError:(NSError **)arg3;
- (_Bool)stopSimulatingLocationWithError:(NSError **)arg1;
@end

@interface DVTAbstractiOSDevice : NSObject
@property (nonatomic, strong) DTDKRemoteDeviceToken *token;
- (id)applications;
@end

@interface DVTiOSDevice : DVTAbstractiOSDevice
- (BOOL)supportsLocationSimulation;
@end

@implementation PhysicalDevice

+ (NSString *)applicationDataPath {
    return [[ShellRunner tmpDir] stringByAppendingPathComponent:@"__appData.xcappdata"];
}

+ (NSString *)pathToXcodePlatformDir {
    NSArray *output  = [ShellRunner xcrun:@[@"xcode-select",
                                            @"--print-path"]];
    if (!output.count) {
        NSLog(@"Error finding developer dir");
        return nil;
    }

    NSString *developerDir = output[0];

    return [[developerDir stringByAppendingPathComponent:@"Platforms"]
            stringByAppendingPathComponent:@"iPhoneOS.platform"];
}

+ (NSDictionary *)infoPlistForInstalledBundleID:(NSString *)bundleID deviceID:(NSString *)deviceID {
    Codesigner *signer = [Codesigner signerThatCannotSign];
    FBDevice *device = [PhysicalDevice deviceForID:deviceID
                                        codesigner:signer];
    return [self infoPlistForInstalledBundleID:bundleID
                                        device:device];
}

+ (NSDictionary *)infoPlistForInstalledBundleID:(NSString *)bundleID device:(FBDevice *)device {
    id<DVTApplication> installed = [((FBiOSDeviceOperator *)device.deviceOperator) installedApplicationWithBundleIdentifier:bundleID];

    if (!installed) {
        NSLog(@"Error fetching installed application %@ ", bundleID);
        return nil;
    }
    return [installed plist];
}


+ (iOSReturnStatusCode)updateAppIfRequired:(NSString *)bundlePath
                                    device:(FBDevice *)device
                                codesigner:(Codesigner *)signerThatCanSign {
    NSError *e;
    FBApplicationDescriptor *app = [FBApplicationDescriptor applicationWithPath:bundlePath
                                                                          error:&e];
    if (e) {
        NSLog(@"Error creating app bundle for %@: %@", bundlePath, e);
        return iOSReturnStatusCodeGenericFailure;
    }

    if ([self appIsInstalled:app.bundleID deviceID:device.udid] == iOSReturnStatusCodeEverythingOkay) {
        NSDictionary *oldPlist = [self infoPlistForInstalledBundleID:app.bundleID device:device];
        NSString *newPlistPath = [bundlePath stringByAppendingPathComponent:@"Info.plist"];
        NSDictionary *newPlist = [NSDictionary dictionaryWithContentsOfFile:newPlistPath];
        if (!newPlist || newPlist.count == 0) {
            NSLog(@"Unable to find Info.plist at %@", newPlistPath);
            return iOSReturnStatusCodeGenericFailure;
        }

        if ([AppUtils appVersionIsDifferent:oldPlist newPlist:newPlist]) {
            NSLog(@"Installed version is different, attempting to update %@.", app.bundleID);
            iOSReturnStatusCode ret = [self uninstallApp:app.bundleID deviceID:device.udid];
            if (ret != iOSReturnStatusCodeEverythingOkay) {
                return ret;
            }
            return [self installApp:bundlePath
                           deviceID:device.udid
                          updateApp:YES
                         codesignID:[signerThatCanSign codeSignIdentity]];
        } else {
            NSLog(@"Latest version of %@ is installed, not reinstalling.", app.bundleID);
        }
    }

    return iOSReturnStatusCodeEverythingOkay;
}

+ (iOSReturnStatusCode)startTestOnDevice:(NSString *)deviceID
                               sessionID:(NSUUID *)sessionID
                          runnerBundleID:(NSString *)runnerBundleID
                               keepAlive:(BOOL)keepAlive  {
    NSLog(@"Starting test with SessionID: %@, DeviceID: %@, runnerBundleID: %@", sessionID, deviceID, runnerBundleID);
    NSError *e = nil;

    Codesigner *signer = [Codesigner signerThatCannotSign];
    FBDevice *device = [self deviceForID:deviceID codesigner:signer];

    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }

    PhysicalDevice *repLog = [PhysicalDevice new];

    FBTestManager *testManager = [FBXCTestRunStrategy startTestManagerForDeviceOperator:device.deviceOperator
                                                                         runnerBundleID:runnerBundleID
                                                                              sessionID:sessionID
                                                                         withAttributes:[FBTestRunnerConfigurationBuilder defaultBuildAttributes]
                                                                            environment:[FBTestRunnerConfigurationBuilder defaultBuildEnvironment]
                                                                               reporter:repLog
                                                                                 logger:repLog
                                                                                  error:&e];
    if (!e) {
        if (keepAlive) {
            /*
                `testingComplete` will be YES when testmanagerd calls
                `testManagerMediatorDidFinishExecutingTestPlan:`
             */
            while (!repLog.testingComplete){
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                
                /*
                    `testingHasFinished` returns YES when the bundle connection AND testmanagerd
                    connection are finished with the connection (presumably at end of test or failure)
                 */
                if ([testManager testingHasFinished]) {
                    break;
                }
            }
        }
    } else {
        NSLog(@"Err: %@", e);
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
                        updateApp:(BOOL)updateApp
                       codesignID:(NSString *)codesignID {

    if (codesignID == nil) {
        CodesignIdentity *identity = [CodesignIdentity identityForAppBundle:pathToBundle deviceId:deviceID];
        if (!identity) {
            NSLog(@"ERROR: Could not find valid codesign identity");
            NSLog(@"ERROR:   app: %@", pathToBundle);
            NSLog(@"ERROR:   device udid: %@", deviceID);
            return iOSReturnStatusCodeNoValidCodesignIdentity;
        }
        codesignID = identity.name;
    }

    Codesigner *signer = [[Codesigner alloc] initWithCodeSignIdentity:codesignID
                                                           deviceUDID:deviceID];

    FBDevice *device = [self deviceForID:deviceID codesigner:signer];

    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }

    NSString *stagedApp = [AppUtils copyAppBundle:pathToBundle];
    if (!stagedApp) {
        NSLog(@"ERROR: Could not stage app for code signing");
        return iOSReturnStatusCodeInternalError;
    }

    NSError *err;
    //Codesign
    FBProductBundle *app = [[[[FBProductBundleBuilder builderWithFileManager:[NSFileManager defaultManager]]
                              withBundlePath:stagedApp]
                             withCodesignProvider:signer]
                            buildWithError:&err];

    if (err) {
        NSLog(@"Error creating product bundle for %@: %@", stagedApp, err);
        return iOSReturnStatusCodeInternalError;
    }

    FBiOSDeviceOperator *op = device.deviceOperator;
    if ([op isApplicationInstalledWithBundleID:app.bundleID error:&err] || err) {
        if (err) {
            NSLog(@"Error checking if app {%@} is installed. %@", app.bundleID, err);
            return iOSReturnStatusCodeInternalError;
        }
        iOSReturnStatusCode ret = [self updateAppIfRequired:stagedApp
                                                     device:device
                                                 codesigner:signer];
        if (ret != iOSReturnStatusCodeEverythingOkay) {
            return ret;
        }
    } else {
        if (![op installApplicationWithPath:stagedApp error:&err] || err) {
            NSLog(@"Error installing application: %@", err);
            return iOSReturnStatusCodeInternalError;
        }
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

+ (iOSReturnStatusCode)setLocation:(NSString *)deviceID
                               lat:(double)lat
                               lng:(double)lng {
    FBDevice *device = [self deviceForID:deviceID codesigner:nil];
    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }

    if (![device.dvtDevice supportsLocationSimulation]) {
        NSLog(@"Device %@ doesn't support location simulation", deviceID);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    [[device.dvtDevice token] simulateLatitude:@(lat)
                                  andLongitude:@(lng)
                                     withError:&e];
    if (e) {
        NSLog(@"Unable to set device location: %@", e);
        return iOSReturnStatusCodeInternalError;
    }

    return iOSReturnStatusCodeEverythingOkay;
}

+ (iOSReturnStatusCode)stopSimulatingLocation:(NSString *)deviceID {
    FBDevice *device = [self deviceForID:deviceID codesigner:nil];
    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }

    if (![device.dvtDevice supportsLocationSimulation]) {
        NSLog(@"Device %@ doesn't support location simulation", deviceID);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    [[device.dvtDevice token] stopSimulatingLocationWithError:&e];
    if (e) {
        NSLog(@"Unable to stop simulating device location: %@", e);
        return iOSReturnStatusCodeInternalError;
    }
    return iOSReturnStatusCodeEverythingOkay;
}

+ (iOSReturnStatusCode)uploadFiles:(NSArray<NSString *> *)filenames
                          toDevice:(NSString *)deviceID
                    forApplication:(NSString *)bundleID {
    FBDevice *device = [self deviceForID:deviceID codesigner:nil];
    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }
    
    FBiOSDeviceOperator *operator = ((FBiOSDeviceOperator *)device.deviceOperator);
    
    NSError *e;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *file in filenames) {
        if (![fm fileExistsAtPath:file]) {
            NSLog(@"%@ doesn't exist!", file);
            return iOSReturnStatusCodeInvalidArguments;
        }
        [operator uploadApplicationDataAtPath:file bundleID:bundleID error:&e];
        if (e) {
            NSLog(@"Error uploading application data: %@", e);
            return iOSReturnStatusCodeInternalError;
        }
    }
    
    return iOSReturnStatusCodeEverythingOkay;
}

@end
