
#import "PhysicalDevice.h"
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import <FBControlCore/FBControlCore.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "ShellRunner.h"
#import "Codesigner.h"
#import "AppUtils.h"
#import "CodesignIdentity.h"
#import "ConsoleWriter.h"

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
- (BOOL)downloadApplicationDataToPath:(NSString *)arg1
forInstalledApplicationWithBundleIdentifier:(NSString *)arg2
                                error:(NSError **)arg3;
@end

@implementation PhysicalDevice

+ (NSString *)applicationDataPath {
    return [[ShellRunner tmpDir] stringByAppendingPathComponent:@"__appData.xcappdata"];
}

+ (NSString *)pathToXcodePlatformDir {
    NSArray *output  = [ShellRunner xcrun:@[@"xcode-select",
                                            @"--print-path"]];
    if (!output.count) {
        ConsoleWriteErr(@"Error finding developer dir");
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
        ConsoleWriteErr(@"Error fetching installed application %@ ", bundleID);
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
        ConsoleWriteErr(@"Error creating app bundle for %@: %@", bundlePath, e);
        return iOSReturnStatusCodeGenericFailure;
    }

    if ([self appIsInstalled:app.bundleID deviceID:device.udid] == iOSReturnStatusCodeEverythingOkay) {
        NSDictionary *oldPlist = [self infoPlistForInstalledBundleID:app.bundleID device:device];
        NSString *newPlistPath = [bundlePath stringByAppendingPathComponent:@"Info.plist"];
        NSDictionary *newPlist = [NSDictionary dictionaryWithContentsOfFile:newPlistPath];
        if (!newPlist || newPlist.count == 0) {
            ConsoleWriteErr(@"Unable to find Info.plist at %@", newPlistPath);
            return iOSReturnStatusCodeGenericFailure;
        }

        if ([AppUtils appVersionIsDifferent:oldPlist newPlist:newPlist]) {
            LogInfo(@"Installed version is different, attempting to update %@.", app.bundleID);
            iOSReturnStatusCode ret = [self uninstallApp:app.bundleID deviceID:device.udid];
            if (ret != iOSReturnStatusCodeEverythingOkay) {
                return ret;
            }
            return [self installApp:bundlePath
                           deviceID:device.udid
                          updateApp:YES
                         codesignID:[signerThatCanSign codeSignIdentity]];
        } else {
            LogInfo(@"Latest version of %@ is installed, not reinstalling.", app.bundleID);
        }
    }

    return iOSReturnStatusCodeEverythingOkay;
}

+ (iOSReturnStatusCode)startTestOnDevice:(NSString *)deviceID
                               sessionID:(NSUUID *)sessionID
                          runnerBundleID:(NSString *)runnerBundleID
                               keepAlive:(BOOL)keepAlive  {
    LogInfo(@"Starting test with SessionID: %@, DeviceID: %@, runnerBundleID: %@", sessionID, deviceID, runnerBundleID);
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
        ConsoleWriteErr(@"Err: %@", e);
        return iOSReturnStatusCodeInternalError;
    }
    return iOSReturnStatusCodeEverythingOkay;
}

#pragma mark - Test Reporter Methods

- (void)testManagerMediatorDidBeginExecutingTestPlan:(FBTestManagerAPIMediator *)mediator {
    LogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
                  testSuite:(NSString *)testSuite
                 didStartAt:(NSString *)startTime {
    LogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator testCaseDidFinishForTestClass:(NSString *)testClass method:(NSString *)method withStatus:(FBTestReportStatus)status duration:(NSTimeInterval)duration {
    LogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator testCaseDidFailForTestClass:(NSString *)testClass method:(NSString *)method withMessage:(NSString *)message file:(NSString *)file line:(NSUInteger)line {
    LogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
testBundleReadyWithProtocolVersion:(NSInteger)protocolVersion
             minimumVersion:(NSInteger)minimumVersion {
    LogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
testCaseDidStartForTestClass:(NSString *)testClass
                     method:(NSString *)method {
    LogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
        finishedWithSummary:(FBTestManagerResultSummary *)summary {
    LogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}


- (void)testManagerMediatorDidFinishExecutingTestPlan:(FBTestManagerAPIMediator *)mediator {
    LogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    self.testingComplete = YES;
}

#pragma mark - FBControlCoreLogger
- (id<FBControlCoreLogger>)log:(NSString *)string {
    LogInfo(@"%@", string);
    return self;
}

- (id<FBControlCoreLogger>)logFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2) {
    va_list args;
    va_start(args, format);
    id str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    LogInfo(@"%@", str);
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
        LogInfo(@"Error getting device with ID %@: %@", deviceID, err);
        return nil;
    }
    device.deviceOperator.codesignProvider = signer;
    [device.deviceOperator waitForDeviceToBecomeAvailableWithError:&err];
    if (err) {
        LogInfo(@"Error getting device with ID %@: %@", deviceID, err);
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
            ConsoleWriteErr(@"Could not find valid codesign identity");
            ConsoleWriteErr(@"  app: %@", pathToBundle);
            ConsoleWriteErr(@"  device udid: %@", deviceID);
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
        ConsoleWriteErr(@"Could not stage app for code signing");
        return iOSReturnStatusCodeInternalError;
    }

    NSError *err;
    //Codesign
    FBProductBundle *app = [[[[FBProductBundleBuilder builderWithFileManager:[NSFileManager defaultManager]]
                              withBundlePath:stagedApp]
                             withCodesignProvider:signer]
                            buildWithError:&err];

    if (err) {
        ConsoleWriteErr(@"Error creating product bundle for %@: %@", stagedApp, err);
        return iOSReturnStatusCodeInternalError;
    }

    FBiOSDeviceOperator *op = device.deviceOperator;
    if ([op isApplicationInstalledWithBundleID:app.bundleID error:&err] || err) {
        if (err) {
            ConsoleWriteErr(@"Error checking if app {%@} is installed. %@", app.bundleID, err);
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
            ConsoleWriteErr(@"Error installing application: %@", err);
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
        ConsoleWriteErr(@"Application %@ is not installed on %@", bundleID, deviceID);
        return iOSReturnStatusCodeInternalError;
    }

    if (err) {
        ConsoleWriteErr(@"Error checking if application %@ is installed: %@", bundleID, err);
        return iOSReturnStatusCodeInternalError;
    }

    if (![op cleanApplicationStateWithBundleIdentifier:bundleID error:&err] || err) {
        ConsoleWriteErr(@"Error uninstalling app %@: %@", bundleID, err);
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
        LogInfo(@"Error checking if %@ is installed to %@: %@", bundleID, deviceID, err);
        return iOSReturnStatusCodeInternalError;
    }
    if (installed) {
        ConsoleWrite(@"true");
    } else {
        ConsoleWrite(@"false");
    }
    return installed ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeFalse;
}

+ (iOSReturnStatusCode)setLocation:(NSString *)deviceID
                               lat:(double)lat
                               lng:(double)lng {
    FBDevice *device = [self deviceForID:deviceID codesigner:nil];
    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }

    if (![device.dvtDevice supportsLocationSimulation]) {
        ConsoleWriteErr(@"Device %@ doesn't support location simulation", deviceID);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    [[device.dvtDevice token] simulateLatitude:@(lat)
                                  andLongitude:@(lng)
                                     withError:&e];
    if (e) {
        ConsoleWriteErr(@"Unable to set device location: %@", e);
        return iOSReturnStatusCodeInternalError;
    }

    return iOSReturnStatusCodeEverythingOkay;
}

+ (iOSReturnStatusCode)stopSimulatingLocation:(NSString *)deviceID {
    FBDevice *device = [self deviceForID:deviceID codesigner:nil];
    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }

    if (![device.dvtDevice supportsLocationSimulation]) {
        ConsoleWriteErr(@"Device %@ doesn't support location simulation", deviceID);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    [[device.dvtDevice token] stopSimulatingLocationWithError:&e];
    if (e) {
        ConsoleWriteErr(@"Unable to stop simulating device location: %@", e);
        return iOSReturnStatusCodeInternalError;
    }
    return iOSReturnStatusCodeEverythingOkay;
}

/*
 The algorithm here is to copy the application's container to the host,
 [over]write the desired file into the appdata bundle, then reupload that
 bundle since apparently uploading an xcappdata bundle is destructive.
 */
+ (iOSReturnStatusCode)uploadFile:(NSString *)filepath
                         toDevice:(NSString *)deviceID
                   forApplication:(NSString *)bundleID
                        overwrite:(BOOL)overwrite {
    FBDevice *device = [self deviceForID:deviceID codesigner:nil];
    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }
    
    FBiOSDeviceOperator *operator = ((FBiOSDeviceOperator *)device.deviceOperator);
    
    NSError *e;
    
    //We make an .xcappdata bundle, place the files there, and upload that
    NSFileManager *fm = [NSFileManager defaultManager];
    
    //Ensure input file exists
    if (![fm fileExistsAtPath:filepath]) {
        ConsoleWriteErr(@"%@ doesn't exist!", filepath);
        return iOSReturnStatusCodeInvalidArguments;
    }
    
    NSString *guid = [NSProcessInfo processInfo].globallyUniqueString;
    NSString *xcappdataName = [NSString stringWithFormat:@"%@.xcappdata", guid];
    NSString *xcappdataPath = [[NSTemporaryDirectory()
                                stringByAppendingPathComponent:guid]
                               stringByAppendingPathComponent:xcappdataName];
    NSString *dataBundle = [[xcappdataPath
                             stringByAppendingPathComponent:@"AppData"]
                            stringByAppendingPathComponent:@"Documents"];
    
    LogInfo(@"Creating .xcappdata bundle at %@", xcappdataPath);
    
    if (![fm createDirectoryAtPath:xcappdataPath
       withIntermediateDirectories:YES
                        attributes:nil
                             error:&e]) {
        ConsoleWriteErr(@"Error creating data dir: %@", e);
        return iOSReturnStatusCodeGenericFailure;
    }
   
    if (![device.dvtDevice downloadApplicationDataToPath:xcappdataPath
             forInstalledApplicationWithBundleIdentifier:bundleID
                                                   error:&e]) {
        ConsoleWriteErr(@"Unable to download app data for %@ to %@: %@",
                        bundleID,
                        xcappdataPath,
                        e);
        return iOSReturnStatusCodeInternalError;
    }
    LogInfo(@"Copied container data for %@ to %@", bundleID, xcappdataPath);
    
    //TODO: depending on `overwrite`, upsert file
    NSString *filename = [filepath lastPathComponent];
    NSString *dest = [dataBundle stringByAppendingPathComponent:filename];
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
    
    if (![operator uploadApplicationDataAtPath:xcappdataPath bundleID:bundleID error:&e]) {
        ConsoleWriteErr(@"Error uploading files to application container: %@", e);
        return iOSReturnStatusCodeInternalError;
    }

    // Remove the temporary data bundle
    if (![fm removeItemAtPath:dataBundle error:&e]) {
        ConsoleWriteErr(@"Could not remove temporary data bundle: %@\n%@",
              dataBundle, e);
    }

    return iOSReturnStatusCodeEverythingOkay;
}

+ (iOSReturnStatusCode)containerPathForApplication:(NSString *)bundleID
                                          onDevice:(NSString *)deviceID {
    FBDevice *device = [self deviceForID:deviceID codesigner:nil];
    if (!device) { return iOSReturnStatusCodeDeviceNotFound; }
    
    FBiOSDeviceOperator *operator = ((FBiOSDeviceOperator *)device.deviceOperator);
    NSError *e;
    
    NSString *path = [operator containerPathForApplicationWithBundleID:bundleID error:&e];
    if (e) {
        ConsoleWriteErr(@"Error getting container path for application %@: %@", bundleID, e);
        return iOSReturnStatusCodeGenericFailure;
    } else {
        ConsoleWrite(@"%@", path);
    }
    return iOSReturnStatusCodeEverythingOkay;
}

@end
