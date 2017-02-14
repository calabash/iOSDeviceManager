
#import "PhysicalDevice.h"
#import <FBControlCore/FBControlCore.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "ShellRunner.h"
#import "Codesigner.h"
#import "AppUtils.h"
#import "CodesignIdentity.h"
#import "ConsoleWriter.h"
#import "Application.h"

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
- (void)installProvisioningProfile:(id)arg1;
@end

@interface DTDKProvisioningProfile : NSObject
+ (DTDKProvisioningProfile *)profileWithPath:(NSString *)path certificateUtilities:(id)utils error:(NSError **)e;
@end

@interface PhysicalDevice()

@property (nonatomic, strong) FBDevice *fbDevice;

@end

@implementation PhysicalDevice

+ (Device *)withID:(NSString *)uuid {
    PhysicalDevice* device = [[PhysicalDevice alloc] init];
    
    device.uuid = uuid;
    
    NSError *err;
    FBDevice *fbDevice = [[FBDeviceSet defaultSetWithLogger:nil
                                                    error:&err]
                                            deviceWithUDID:uuid];
    if (!fbDevice || err) {
        ConsoleWriteErr(@"Error getting device with ID %@: %@", uuid, err);
        return nil;
    }

    [fbDevice.deviceOperator waitForDeviceToBecomeAvailableWithError:&err];
    if (err) {
        ConsoleWriteErr(@"Error getting device with ID %@: %@", uuid, err);
        return nil;
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

- (iOSReturnStatusCode)installApp:(Application *)app
                    mobileProfile:(MobileProfile *)profile
                 codesignIdentity:(CodesignIdentity *)codesignID
                     shouldUpdate:(BOOL)shouldUpdate {
    if (!self.fbDevice) { return iOSReturnStatusCodeDeviceNotFound; }
    
    NSError *err;
    FBiOSDeviceOperator *op = self.fbDevice.deviceOperator;
    BOOL needsToInstall = YES;
    
    //First check if the app is installed
    if ([op isApplicationInstalledWithBundleID:app.bundleID error:&err] || err) {
        if (err) {
            ConsoleWriteErr(@"Error checking if app (%@) is installed. %@", app.bundleID, err);
            return iOSReturnStatusCodeInternalError;
        }
        
        //If it's installed and the user opted for no update, we're done.
        if (!shouldUpdate) {
            return iOSReturnStatusCodeEverythingOkay;
        }
        
        iOSReturnStatusCode ret = iOSReturnStatusCodeEverythingOkay;
        
        //Check if the app differs from the installed version
        needsToInstall = [self shouldUpdateApp:app statusCode:&ret];
        if (ret != iOSReturnStatusCodeEverythingOkay) {
            return ret;
        }
    }
    
    //Only codesign/install if we actually need to.
    if (needsToInstall) {
        //TODO: Skip resigning if the app is already signed for the device?
        //Requires reading provisioning profiles on the device and comparing
        //entitlements...
        if (codesignID) {
            ConsoleWriteErr(@"Deprecated behavior - resigning application with codesign identity: %@", codesignID);
            profile = [MobileProfile bestMatchProfileForApplication:app
                                                             device:self
                                                   codesignIdentity:codesignID];
            if (!profile) {
                ConsoleWriteErr(@"Unable to find valid profile for codesignID: %@", codesignID);
                return iOSReturnStatusCodeInternalError;
            }
            [Codesigner resignApplication:app
                  withProvisioningProfile:profile
                     withCodesignIdentity:codesignID];
        } else {
            if (!profile) {
                profile = [MobileProfile bestMatchProfileForApplication:app device:self];
                NSAssert(profile != nil,
                         @"Unable to find profile matching app %@ and device %@",
                         app.path,
                         self.uuid);
            }
            [Codesigner resignApplication:app withProvisioningProfile:profile];
        }
        // Log entitlement comparisons
        [Entitlements compareEntitlementsWithProfile:profile app:app];
        
        // Install profile to device
        Class DTDKProvisioniingProfile = NSClassFromString(@"DTDKProvisioningProfile");
        DTDKProvisioningProfile *_profile = [DTDKProvisioniingProfile profileWithPath:profile.path
                                                                 certificateUtilities:nil
                                                                                error:&err];
        if (err) {
            ConsoleWriteErr(@"Failed to install profile: %@ due to error: %@", profile.path, err);
            return iOSReturnStatusCodeInternalError;
        }
        
        [self.fbDevice.dvtDevice installProvisioningProfile:_profile];
        
        if (![op installApplicationWithPath:app.path error:&err] || err) {
            ConsoleWriteErr(@"Error installing application: %@", err);
            return iOSReturnStatusCodeInternalError;
        }
    }
    
    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)installApp:(Application *)app
                    mobileProfile:(MobileProfile *)profile
                     shouldUpdate:(BOOL)shouldUpdate {
    return [self installApp:app
              mobileProfile:profile
           codesignIdentity:nil
               shouldUpdate:shouldUpdate];
}

- (iOSReturnStatusCode)installApp:(Application *)app
                 codesignIdentity:(CodesignIdentity *)codesignID
                     shouldUpdate:(BOOL)shouldUpdate{
    return [self installApp:app
              mobileProfile:nil
           codesignIdentity:codesignID
               shouldUpdate:shouldUpdate];
}

- (iOSReturnStatusCode)installApp:(Application *)app shouldUpdate:(BOOL)shouldUpdate {
    return [self installApp:app
              mobileProfile:nil
           codesignIdentity:nil
               shouldUpdate:shouldUpdate];
}

- (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID {
    
    FBiOSDeviceOperator *op = self.fbDevice.deviceOperator;
    
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

    if (![self.fbDevice.dvtDevice supportsLocationSimulation]) {
        ConsoleWriteErr(@"Device %@ doesn't support location simulation", [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    [[self.fbDevice.dvtDevice token] simulateLatitude:@(lat)
                                  andLongitude:@(lng)
                                     withError:&e];
    if (e) {
        ConsoleWriteErr(@"Unable to set device location: %@", e);
        return iOSReturnStatusCodeInternalError;
    }

    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)stopSimulatingLocation {
    if (![self.fbDevice.dvtDevice supportsLocationSimulation]) {
        ConsoleWriteErr(@"Device %@ doesn't support location simulation", [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    [[self.fbDevice.dvtDevice token] stopSimulatingLocationWithError:&e];
    if (e) {
        ConsoleWriteErr(@"Unable to stop simulating device location: %@", e);
        return iOSReturnStatusCodeInternalError;
    }
    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)launchApp:(NSString *)bundleID {

    // Currently unsupported to have environment vars passed here.
    FBApplicationLaunchConfiguration *appLaunch = [FBApplicationLaunchConfiguration
                                                   configurationWithBundleID:bundleID
                                                   bundleName:nil
                                                   arguments:@[]
                                                   environment:@{}
                                                   output:[FBProcessOutputConfiguration defaultForDeviceManager]];

    NSError *error;

    FBiOSDeviceOperator *deviceOperator = (FBiOSDeviceOperator *)self.fbDevice.deviceOperator;
    if (! [deviceOperator launchApplication:appLaunch error:&error]) {
        ConsoleWriteErr(@"Failed launching app with bundleID: %@ due to error: %@", bundleID, error);
        return iOSReturnStatusCodeInternalError;
    }
    
    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)killApp:(NSString *)bundleID {
    
    NSError *error;
    BOOL result = [self.fbDevice killApplicationWithBundleID:bundleID error:&error];
    
    if (error) {
        ConsoleWriteErr(@"Failed killing app with bundle ID: %@ due to: %@", bundleID, error);
        return iOSReturnStatusCodeInternalError;
    }
    
    if (result) {
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        return iOSReturnStatusCodeFalse;
    }
}

- (BOOL) isInstalled:(NSString *)bundleID withError:(NSError **)error {
    FBiOSDeviceOperator *deviceOperator = (FBiOSDeviceOperator *)self.fbDevice.deviceOperator;
    BOOL installed = [deviceOperator isApplicationInstalledWithBundleID:bundleID
                                                                  error:error];
    if (installed) {
        return YES;
    } else {
        return NO;
    }
}

- (iOSReturnStatusCode)isInstalled:(NSString *)bundleID {
    NSError *err;
    BOOL installed = [self isInstalled:bundleID withError:&err];
    
    if (err) {
        ConsoleWriteErr(@"Error checking if %@ is installed to %@: %@", bundleID, [self uuid], err);
        @throw [NSException exceptionWithName:@"IsInstalledAppException"
                                       reason:@"Unable to determine if application is installed"
                                     userInfo:nil];
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
    NSError *err = nil;
    if (![self isInstalled:bundleID withError:&err] || err) {
        return nil;
    }

    FBiOSDeviceOperator *deviceOperator = (FBiOSDeviceOperator *)self.fbDevice.deviceOperator;
    id<DVTApplication> installedDVTApplication = [deviceOperator installedApplicationWithBundleIdentifier:bundleID];

    return [Application withBundleID:bundleID
                               plist:[installedDVTApplication plist]
                       architectures:self.fbDevice.supportedArchitectures];
}

- (iOSReturnStatusCode)startTestWithRunnerID:(NSString *)runnerID
                                   sessionID:(NSUUID *)sessionID
                                   keepAlive:(BOOL)keepAlive{
    if (![self isInstalled:runnerID withError:nil]) {
        ConsoleWriteErr(@"Attempted to start test with runner id: %@ but app is not installed", runnerID);
        return iOSReturnStatusCodeInternalError;
    }
    
    LogInfo(@"Starting test with SessionID: %@, DeviceID: %@, runnerBundleID: %@", sessionID, [self uuid], runnerID);
    NSError *e = nil;

    FBTestManager *testManager = [FBXCTestRunStrategy startTestManagerForIOSTarget:self.fbDevice
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
            
            FBRunLoopSpinner *spinner = [FBRunLoopSpinner new];
            [spinner spinUntilTrue:^BOOL () {
                return ([testManager testingHasFinished] && self.testingComplete);
            }];
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

    FBiOSDeviceOperator *operator = ((FBiOSDeviceOperator *)self.fbDevice.deviceOperator);

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

    if (![self.fbDevice.dvtDevice downloadApplicationDataToPath:xcappdataPath
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
