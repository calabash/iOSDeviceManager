
#import "PhysicalDevice.h"
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

@interface PhysicalDevice()

@property (nonatomic, strong) FBDevice *fbDevice;

@end

@implementation PhysicalDevice

+ (Device *)withID:(NSString *)uuid {
    PhysicalDevice* device = [[PhysicalDevice alloc] init];
    
    device.uuid = uuid;
    device.identities = [[NSMutableArray alloc] init];
    
    NSError *err;
    FBDevice *fbDevice = [[FBDeviceSet defaultSetWithLogger:nil
                                                    error:&err]
                                            deviceWithUDID:uuid];
    if (!fbDevice || err) {
        LogInfo(@"Error getting device with ID %@: %@", uuid, err);
        
        @throw [NSException exceptionWithName:@"DeviceNotFoundException"
                                       reason:@"Error getting device"
                                     userInfo:nil];
    }
    
    Codesigner *signer = [[Codesigner alloc] initWithCodeSignIdentity:nil
                                                           deviceUDID:uuid];
    fbDevice.deviceOperator.codesignProvider = signer;

    [fbDevice.deviceOperator waitForDeviceToBecomeAvailableWithError:&err];
    if (err) {
        LogInfo(@"Error getting device with ID %@: %@", uuid, err);
        @throw [NSException exceptionWithName:@"DeviceAvailabilityTimeoutException"
                                       reason:@"Failed waiting for device to become available"
                                     userInfo:nil];
    }
    
    device.fbDevice = fbDevice;

    return device;
}

- (iOSReturnStatusCode)launch {
    return iOSReturnStatusCodeGenericFailure;
}

- (iOSReturnStatusCode)kill {
    return iOSReturnStatusCodeGenericFailure;
}

- (iOSReturnStatusCode)installApp:(Application *)app shouldUpdate:(BOOL)shouldUpdate {
    CodesignIdentity *identity = [[self identities] firstObject];
    if (identity == nil) {
        identity = [CodesignIdentity identityForAppBundle:app.path deviceId:[self uuid]];
        if (!identity) {
            ConsoleWriteErr(@"Could not find valid codesign identity");
            ConsoleWriteErr(@"  app: %@", app.path);
            ConsoleWriteErr(@"  device udid: %@", [self uuid]);
            return iOSReturnStatusCodeNoValidCodesignIdentity;
        }
    }
    
    NSString *codesignID = identity.name;
    
    Codesigner *signer = [[Codesigner alloc] initWithCodeSignIdentity:codesignID
                                                           deviceUDID:[self uuid]];
    _fbDevice.deviceOperator.codesignProvider = signer;
    
    if (!_fbDevice) { return iOSReturnStatusCodeDeviceNotFound; }
    
    NSString *stagedApp = [AppUtils copyAppBundle:app.path];
    if (!stagedApp) {
        ConsoleWriteErr(@"Could not stage app for code signing");
        return iOSReturnStatusCodeInternalError;
    }
    
    NSError *err;
    //Codesign
    FBProductBundle *codesignedApp = [[[[FBProductBundleBuilder builderWithFileManager:[NSFileManager defaultManager]]
                              withBundlePath:stagedApp]
                             withCodesignProvider:signer]
                            buildWithError:&err];
    
    if (err) {
        ConsoleWriteErr(@"Error creating product bundle for %@: %@", stagedApp, err);
        return iOSReturnStatusCodeInternalError;
    }
    
    FBiOSDeviceOperator *op = _fbDevice.deviceOperator;
    if ([op isApplicationInstalledWithBundleID:codesignedApp.bundleID error:&err] || err) {
        if (err) {
            ConsoleWriteErr(@"Error checking if app {%@} is installed. %@", codesignedApp.bundleID, err);
            return iOSReturnStatusCodeInternalError;
        }
        iOSReturnStatusCode ret = [self updateAppIfRequired:app
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

- (iOSReturnStatusCode)updateAppIfRequired:(Application *)app
                                codesigner:(Codesigner *)signerThatCanSign {

    if ([self isInstalled:app.bundleID] == iOSReturnStatusCodeEverythingOkay) {
        Application *installedApp = [self installedApp:app.bundleID];
        NSDictionary *oldPlist = installedApp.infoPlist;
        NSDictionary *newPlist = app.infoPlist;
        if (!newPlist || newPlist.count == 0) {
            ConsoleWriteErr(@"Unable to find Info.plist for bundle path %@", app.path);
            return iOSReturnStatusCodeGenericFailure;
        }

        if ([AppUtils appVersionIsDifferent:oldPlist newPlist:newPlist]) {
            LogInfo(@"Installed version is different, attempting to update %@.", app.bundleID);
            iOSReturnStatusCode ret = [self uninstallApp:app.bundleID];
            if (ret != iOSReturnStatusCodeEverythingOkay) {
                return ret;
            }

            return [self installApp:app shouldUpdate:YES];
        } else {
            LogInfo(@"Latest version of %@ is installed, not reinstalling.", app.bundleID);
        }
    }

    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID {
    
    FBiOSDeviceOperator *op = _fbDevice.deviceOperator;
    
    NSError *err;
    if (![op isApplicationInstalledWithBundleID:bundleID error:&err]) {
        ConsoleWriteErr(@"Application %@ is not installed on %@", bundleID, [self uuid]);
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

- (iOSReturnStatusCode)simulateLocationWithLat:(double)lat lng:(double)lng {

    if (![_fbDevice.dvtDevice supportsLocationSimulation]) {
        ConsoleWriteErr(@"Device %@ doesn't support location simulation", [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    [[_fbDevice.dvtDevice token] simulateLatitude:@(lat)
                                  andLongitude:@(lng)
                                     withError:&e];
    if (e) {
        ConsoleWriteErr(@"Unable to set device location: %@", e);
        return iOSReturnStatusCodeInternalError;
    }

    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)stopSimulatingLocation {

    if (![_fbDevice.dvtDevice supportsLocationSimulation]) {
        ConsoleWriteErr(@"Device %@ doesn't support location simulation", [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    [[_fbDevice.dvtDevice token] stopSimulatingLocationWithError:&e];
    if (e) {
        ConsoleWriteErr(@"Unable to stop simulating device location: %@", e);
        return iOSReturnStatusCodeInternalError;
    }
    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)launchApp:(NSString *)bundleID {
    return iOSReturnStatusCodeGenericFailure;
}

- (iOSReturnStatusCode)killApp:(NSString *)bundleID {
    return iOSReturnStatusCodeGenericFailure;
}

- (iOSReturnStatusCode)isInstalled:(NSString *)bundleID {

    NSError *err;
    BOOL installed = [_fbDevice.deviceOperator isApplicationInstalledWithBundleID:bundleID
                                                                         error:&err];
    if (err) {
        LogInfo(@"Error checking if %@ is installed to %@: %@", bundleID, [self uuid], err);
        return iOSReturnStatusCodeFalse;
    }
    
    if (installed) {
        ConsoleWrite(@"true");
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        ConsoleWrite(@"false");
        return iOSReturnStatusCodeFalse;
    }
}

- (Application *)installedApp:(NSString *)bundleID {
    NSError *err;
    NSString *pathToBundle = [_fbDevice.deviceOperator applicationPathForApplicationWithBundleID:bundleID error:&err];
    
    if (err) {
        LogInfo(@"Error determining application path for bundle ID: %@", bundleID);
        return nil;
    }
    
    return [Application withBundlePath:pathToBundle];
}

- (iOSReturnStatusCode)startTestWithRunnerID:(NSString *)runnerID sessionID:(NSUUID *)sessionID keepAlive:(BOOL)keepAlive {
    LogInfo(@"Starting test with SessionID: %@, DeviceID: %@, runnerBundleID: %@", sessionID, [self uuid], runnerID);
    NSError *e = nil;

    FBTestManager *testManager = [FBXCTestRunStrategy startTestManagerForDeviceOperator:_fbDevice.deviceOperator
                                                                         runnerBundleID:runnerID
                                                                              sessionID:sessionID
                                                                         withAttributes:[FBTestRunnerConfigurationBuilder defaultBuildAttributes]
                                                                            environment:[FBTestRunnerConfigurationBuilder defaultBuildEnvironment]
                                                                               reporter:self
                                                                                 logger:self
                                                                                  error:&e];
    if (!e) {
        if (keepAlive) {
            /*
                `testingComplete` will be YES when testmanagerd calls
                `testManagerMediatorDidFinishExecutingTestPlan:`
             */
            while (!self.testingComplete){
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

///*
// The algorithm here is to copy the application's container to the host,
// [over]write the desired file into the appdata bundle, then reupload that
// bundle since apparently uploading an xcappdata bundle is destructive.
// */
- (iOSReturnStatusCode)uploadFile:(NSString *)filepath forApplication:(NSString *)bundleID overwrite:(BOOL)overwrite {

    FBiOSDeviceOperator *operator = ((FBiOSDeviceOperator *)_fbDevice.deviceOperator);

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

    if (![_fbDevice.dvtDevice downloadApplicationDataToPath:xcappdataPath
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

@end
