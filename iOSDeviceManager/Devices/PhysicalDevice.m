
#import "PhysicalDevice.h"
#import <FBControlCore/FBControlCore.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "ShellRunner.h"
#import "Codesigner.h"
#import "AppUtils.h"
#import "CodesignIdentity.h"
#import "ConsoleWriter.h"
#import "Application.h"
#import "XCTestConfigurationPlist.h"
#import "XCAppDataBundle.h"

@interface FBiOSDeviceOperator (iOSDeviceManagerAdditions)

- (void)fetchApplications;
- (BOOL)killProcessWithID:(NSInteger)processID error:(NSError **)error;

// The keys-value pairs that are available in the plist returned by
// #installedApplicationWithBundleIdentifier:error:
+ (NSDictionary *)applicationReturnAttributesDictionary;
- (NSDictionary *)AMDinstalledApplicationWithBundleIdentifier:(NSString *)bundleID;

// These will probably be moved to FBDeviceApplicationCommands
- (BOOL)isApplicationInstalledWithBundleID:(NSString *)bundleID error:(NSError **)error;
- (BOOL)launchApplication:(FBApplicationLaunchConfiguration *)configuration
                    error:(NSError **)error;

// Originally, we used DVT APIs to install provisioning profiles.
// Facebook is migrating from DVT to MobileDevice (Apple MD) APIs.
// If we find there is a problem with the MobileDevice API we can
// fall back on the DVT implementation.
// - (BOOL)DVTinstallProvisioningProfileAtPath:(NSString *)path error:(NSError **)error;
- (BOOL)AMDinstallProvisioningProfileAtPath:(NSString *)path error:(NSError **)error;

@end

@protocol DVTApplication
- (NSDictionary *)plist;
@end

@interface DTDKRemoteDeviceToken : NSObject
- (BOOL)simulateLatitude:(NSNumber *)lat
            andLongitude:(NSNumber *)lng
               withError:(NSError **)arg3;
- (BOOL)stopSimulatingLocationWithError:(NSError **)arg1;
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
+ (DTDKProvisioningProfile *)profileWithPath:(NSString *)path
                        certificateUtilities:(id)utils
                                       error:(NSError **)e;
@end

@interface PhysicalDevice()

@property (nonatomic, strong) FBDevice *fbDevice;
@property (atomic, strong, readonly) FBDeviceApplicationCommands *applicationCommands;

- (BOOL)installProvisioningProfileAtPath:(NSString *)path
                                   error:(NSError **)error;
@end

@implementation PhysicalDevice

@synthesize applicationCommands = _applicationCommands;

+ (PhysicalDevice *)withID:(NSString *)uuid {
    PhysicalDevice* device = [[PhysicalDevice alloc] init];

    device.uuid = uuid;

    NSError *err;
    FBDevice *fbDevice = [[FBDeviceSet defaultSetWithLogger:nil
                                                      error:&err]
                          deviceWithUDID:uuid];
    if (!fbDevice) {
        ConsoleWriteErr(@"Error getting device with ID %@: %@", uuid, err);
        return nil;
    }

    if (![fbDevice.deviceOperator waitForDeviceToBecomeAvailableWithError:&err]) {
        ConsoleWriteErr(@"Error getting device with ID %@: %@", uuid, err);
        return nil;
    }

    device.fbDevice = fbDevice;

    return device;
}

- (FBDeviceApplicationCommands *)applicationCommands {
    if (_applicationCommands) { return _applicationCommands; }

    _applicationCommands = [FBDeviceApplicationCommands commandsWithDevice:self.fbDevice];
    return _applicationCommands;
}

- (FBiOSDeviceOperator *)fbDeviceOperator {
    return [FBiOSDeviceOperator forDevice:self.fbDevice];
}

- (iOSReturnStatusCode)launch {
    return iOSReturnStatusCodeGenericFailure;
}

- (iOSReturnStatusCode)kill {
    return iOSReturnStatusCodeGenericFailure;
}

- (MobileProfile *)resignApp:(Application *)app
                    identity:(CodesignIdentity *)identity
           resourcesToInject:(NSArray<NSString *> *)resourcePaths {
    ConsoleWriteErr(@"Deprecated behavior - resigning application with codesign "
                    "identity: %@", identity);
    MobileProfile *profile = [MobileProfile bestMatchProfileForApplication:app
                                                                    device:self
                                                          codesignIdentity:identity];
    if (!profile) {
        ConsoleWriteErr(@"Unable to find valid profile for codesign identity: %@", identity);
        return nil;
    }
    [Codesigner resignApplication:app
          withProvisioningProfile:profile
             withCodesignIdentity:identity
                resourcesToInject:resourcePaths];
    return profile;
}

- (iOSReturnStatusCode)installApp:(Application *)app
                    mobileProfile:(MobileProfile *)profile
                 codesignIdentity:(CodesignIdentity *)codesignID
                resourcesToInject:(NSArray<NSString *> *)resourcePaths
                     forceReinstall:(BOOL)forceReinstall {

    BOOL needsInstall = YES;
    Application *installedApp = [self installedApp:app.bundleID];
    
    if (!forceReinstall && installedApp) {
        iOSReturnStatusCode statusCode = iOSReturnStatusCodeEverythingOkay;
        needsInstall = [self shouldUpdateApp:app
                                installedApp:installedApp
                                  statusCode:&statusCode];
        if (statusCode != iOSReturnStatusCodeEverythingOkay) {
            return statusCode;
        }
    }

    if (needsInstall || forceReinstall) {
        // Uninstall app to avoid application-identifier entitlement mismatch
        [self uninstallApp:app.bundleID];
        
        if (codesignID) {
            profile = [self resignApp:app
                             identity:codesignID
                    resourcesToInject:resourcePaths];
            if (!profile) {
                return iOSReturnStatusCodeInternalError;
            }
        } else {
            if (!profile) {
                profile = [MobileProfile bestMatchProfileForApplication:app device:self];
                if (!profile) {
                    ConsoleWriteErr(@"Unable to find profile matching app %@ and device %@",
                                    app.path, self.uuid);
                    return iOSReturnStatusCodeInternalError;
                }
            }
            [Codesigner resignApplication:app
                  withProvisioningProfile:profile
                     withCodesignIdentity:nil
                        resourcesToInject:resourcePaths];
        }

        NSError *error = nil;
        [Entitlements compareEntitlementsWithProfile:profile app:app];

        if (![self installProvisioningProfileAtPath:profile.path error:&error]) {
            ConsoleWriteErr(@"Failed to install profile: %@ due to error: %@",
                            profile.path, [error localizedDescription]);
            return iOSReturnStatusCodeInternalError;
        }

        if (![self.applicationCommands installApplicationWithPath:app.path
                                                            error:&error]) {
            ConsoleWriteErr(@"Error installing application: %@",
                            [error localizedDescription]);
            return iOSReturnStatusCodeInternalError;
        }
        
        ConsoleWrite(@"Installed %@ version: %@ / %@ to %@", app.bundleID,
                        app.bundleShortVersion, app.bundleVersion, [self uuid]);
    }

    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)installApp:(Application *)app
                    mobileProfile:(MobileProfile *)profile
                     forceReinstall:(BOOL)forceReinstall {
    return [self installApp:app
              mobileProfile:profile
           codesignIdentity:nil
          resourcesToInject:nil
               forceReinstall:forceReinstall];
}

- (iOSReturnStatusCode)installApp:(Application *)app
                 codesignIdentity:(CodesignIdentity *)codesignID
                     forceReinstall:(BOOL)forceReinstall{
    return [self installApp:app
              mobileProfile:nil
           codesignIdentity:codesignID
          resourcesToInject:nil
               forceReinstall:forceReinstall];
}

- (iOSReturnStatusCode)installApp:(Application *)app forceReinstall:(BOOL)forceReinstall {
    return [self installApp:app
              mobileProfile:nil
           codesignIdentity:nil
          resourcesToInject:nil
               forceReinstall:forceReinstall];
}

- (iOSReturnStatusCode)installApp:(Application *)app
                resourcesToInject:(NSArray<NSString *> *)resourcePaths
                     forceReinstall:(BOOL)forceReinstall {
    return [self installApp:app
              mobileProfile:nil
           codesignIdentity:nil
          resourcesToInject:resourcePaths
               forceReinstall:forceReinstall];
}

- (iOSReturnStatusCode)installApp:(Application *)app
                    mobileProfile:(MobileProfile *)profile
                resourcesToInject:(NSArray<NSString *> *)resourcePaths
                     forceReinstall:(BOOL)forceReinstall {
    return [self installApp:app
              mobileProfile:profile
           codesignIdentity:nil
          resourcesToInject:resourcePaths
               forceReinstall:forceReinstall];
}

- (iOSReturnStatusCode)installApp:(Application *)app
                 codesignIdentity:(CodesignIdentity *)codesignID
                resourcesToInject:(NSArray<NSString *> *)resourcePaths
                     forceReinstall:(BOOL)forceReinstall {
    return [self installApp:app
              mobileProfile:nil
           codesignIdentity:codesignID
          resourcesToInject:resourcePaths
               forceReinstall:forceReinstall];
}

- (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID {

    FBiOSDeviceOperator *operator = [self fbDeviceOperator];

    NSError *err;
    if (![operator isApplicationInstalledWithBundleID:bundleID error:&err]) {
        ConsoleWriteErr(@"Application %@ is not installed on %@", bundleID, [self uuid]);
        return iOSReturnStatusCodeInternalError;
    }

    if (err) {
        ConsoleWriteErr(@"Error checking if application %@ is installed: %@", bundleID, err);
        return iOSReturnStatusCodeInternalError;
    }

    if (![self terminateApplication:bundleID wasRunning:nil]) {
        return iOSReturnStatusCodeInternalError;
    }

    if (![self.applicationCommands uninstallApplicationWithBundleID:bundleID
                                                              error:&err]) {
        ConsoleWriteErr(@"Error uninstalling app %@: %@", bundleID, err);
        return iOSReturnStatusCodeInternalError;
    } else {
        return iOSReturnStatusCodeEverythingOkay;
    }
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
                                                   waitForDebugger:NO
                                                   output:[FBProcessOutputConfiguration defaultForDeviceManager]];

    NSError *error = nil;

    FBiOSDeviceOperator *deviceOperator = [self fbDeviceOperator];
    if (![deviceOperator launchApplication:appLaunch error:&error]) {
        ConsoleWriteErr(@"Failed launching app with bundleID: %@ due to error: %@", bundleID, error);
        return iOSReturnStatusCodeInternalError;
    }

    return iOSReturnStatusCodeEverythingOkay;
}

- (BOOL)launchApplicationWithConfiguration:(FBApplicationLaunchConfiguration *)configuration
                                     error:(NSError **)error {
    return [self.fbDeviceOperator launchApplication:configuration error:error];
}

- (iOSReturnStatusCode)killApp:(NSString *)bundleID {
    BOOL wasRunning;

    BOOL success = [self terminateApplication:bundleID wasRunning:&wasRunning];

    if (success) {
        if (wasRunning) {
            ConsoleWrite(@"Terminated application: %@", bundleID);
        } else {
            ConsoleWrite(@"Application: %@ was not running.", bundleID);
        }
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        return iOSReturnStatusCodeInternalError;
    }
}

- (pid_t)processIdentifierForApplication:(NSString *)bundleIdentifier {
    NSError *error = nil;
    FBiOSDeviceOperator *operator = self.fbDeviceOperator;
    pid_t PID = [operator processIDWithBundleID:bundleIdentifier error:&error];
    if (PID < 1) {
        return 0;
    } else {
        return PID;
    }
}

- (BOOL)applicationIsRunning:(NSString *)bundleIdentifier {
    return [self processIdentifierForApplication:bundleIdentifier] != 0;
}

- (BOOL)terminateApplication:(NSString *)bundleIdentifier
                  wasRunning:(BOOL *)wasRunning {

    NSError *error = nil;

    FBiOSDeviceOperator *operator = self.fbDeviceOperator;
    pid_t PID = [operator processIDWithBundleID:bundleIdentifier error:&error];
    if (PID < 1) {
        if (wasRunning) { *wasRunning = NO; }
        return YES;
    } else {
        if (wasRunning) { *wasRunning = YES; }
    }

    if (![operator killProcessWithID:PID error:&error]) {
        ConsoleWriteErr(@"Failed to terminate app %@\n  %@",
                        bundleIdentifier, [error localizedDescription]);
        return NO;
    } else {
        return YES;
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
    FBiOSDeviceOperator *deviceOperator = [self fbDeviceOperator];
    NSDictionary *plist;
    plist = [deviceOperator AMDinstalledApplicationWithBundleIdentifier:bundleID];
    if (plist) {
        return [Application withBundleID:bundleID
                                   plist:plist
                           architectures:self.fbDevice.supportedArchitectures];
    } else {
        return nil;
    }
}


- (iOSReturnStatusCode)uploadFile:(NSString *)filepath
                   forApplication:(NSString *)bundleID
                        overwrite:(BOOL)overwrite {

    FBiOSDeviceOperator *operator = [self fbDeviceOperator];
    NSError *e;
    NSFileManager *fm = [NSFileManager defaultManager];

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

    // TODO This call needs to be removed
    [operator fetchApplications];
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

    NSString *filename = [filepath lastPathComponent];
    NSString *dest = [dataBundle stringByAppendingPathComponent:filename];
    if ([fm fileExistsAtPath:dest]) {
        if (!overwrite) {
            ConsoleWriteErr(@"'%@' already exists in the app container.\n"
                            "Specify `-o true` to overwrite.", filename);
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

    [ConsoleWriter write:dest];
    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)downloadXCAppDataBundleForApplication:(NSString *)bundleIdentifier
                                                      toPath:(NSString *)path{
    NSError *e;
    FBiOSDeviceOperator *operator = [self fbDeviceOperator];
    [operator fetchApplications];
    if (![self.fbDevice.dvtDevice downloadApplicationDataToPath:path
                    forInstalledApplicationWithBundleIdentifier:bundleIdentifier
                                                          error:&e]) {
        ConsoleWriteErr(@"Unable to download app data for %@ to %@: %@",
                        bundleIdentifier,
                        path,
                        e);
        return iOSReturnStatusCodeInternalError;
    }
    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)uploadXCAppDataBundle:(NSString *)xcappdata
                              forApplication:(NSString *)bundleIdentifier {
    if (![XCAppDataBundle isValid:xcappdata]) {
        return iOSReturnStatusCodeGenericFailure;
    }

    FBiOSDeviceOperator *operator = [self fbDeviceOperator];
    [operator fetchApplications];

    NSError *error = nil;
    if (![operator uploadApplicationDataAtPath:xcappdata
                                      bundleID:bundleIdentifier
                                         error:&error]) {
        ConsoleWriteErr(@"Error uploading files to application container: %@",
                        [error localizedDescription]);
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

- (NSString *)containerPathForApplication:(NSString *)bundleID {
    FBiOSDeviceOperator *operator = ((FBiOSDeviceOperator *)self.fbDevice.deviceOperator);
    return [operator containerPathForApplicationWithBundleID:bundleID
                                                       error:nil];
}

- (NSString *)installPathForApplication:(NSString *)bundleID {
    FBiOSDeviceOperator *operator = ((FBiOSDeviceOperator *)self.fbDevice.deviceOperator);
    return [operator applicationPathForApplicationWithBundleID:bundleID
                                                         error:nil];
}

- (NSString *)pathToEmptyXcappdata:(NSError **)error {

    NSString *guid = [NSProcessInfo processInfo].globallyUniqueString;
    NSString *xcappdataName = [NSString stringWithFormat:@"%@.xcappdata", guid];
    NSString *xcappdataPath = [[NSTemporaryDirectory()
                                stringByAppendingPathComponent:guid]
                               stringByAppendingPathComponent:xcappdataName];
    NSString *documents = [[xcappdataPath
                            stringByAppendingPathComponent:@"AppData"]
                           stringByAppendingPathComponent:@"Documents"];

    NSString *library = [[xcappdataPath
                          stringByAppendingPathComponent:@"AppData"]
                         stringByAppendingPathComponent:@"Library"];

    NSString *tmp = [[xcappdataPath
                      stringByAppendingPathComponent:@"AppData"]
                     stringByAppendingPathComponent:@"tmp"];
    for (NSString *path in @[documents, library, tmp]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:path
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:error]) {
            return nil;
        }
    }
    return xcappdataPath;
}

- (BOOL)installProvisioningProfileAtPath:(NSString *)path
                                   error:(NSError **)error {
    FBiOSDeviceOperator *operator = ((FBiOSDeviceOperator *)self.fbDevice.deviceOperator);

    return [operator AMDinstallProvisioningProfileAtPath:path error:error];
}

- (BOOL)stageXctestConfigurationToTmpForBundleIdentifier:(NSString *)bundleIdentifier
                                                   error:(NSError **)error {

    NSString *directory = NSTemporaryDirectory();
    [XCAppDataBundle generateBundleSkeleton:directory
                                       name:@"DeviceAgent.xcappdata"
                                  overwrite:YES];

    NSString *xcappdata = [directory stringByAppendingPathComponent:@"DeviceAgent.xcappdata"];

    if (!xcappdata) { return NO; }

    FBiOSDeviceOperator *operator = [self fbDeviceOperator];
    [operator fetchApplications];

    NSString *runnerPath;
    runnerPath = [operator applicationPathForApplicationWithBundleID:bundleIdentifier
                                                               error:error];
    if (!runnerPath) { return NO; }

    NSString *xctestBundlePath = [self xctestBundlePathForTestRunnerAtPath:runnerPath];
    NSString *xctestconfig = [XCTestConfigurationPlist plistWithTestBundlePath:xctestBundlePath];

    NSString *tmpDirectory = [[xcappdata stringByAppendingPathComponent:@"AppData"]
                              stringByAppendingPathComponent:@"tmp"];

    NSString *filename = @"DeviceAgent.xctestconfiguration";
    NSString *xctestconfigPath = [tmpDirectory stringByAppendingPathComponent:filename];

    if (![xctestconfig writeToFile:xctestconfigPath
                        atomically:YES
                          encoding:NSUTF8StringEncoding
                             error:error]) {
        ConsoleWriteErr(@"Could not create an .xctestconfiguration at path:\n  %@\n",
                        xctestconfigPath);
        return NO;
    }

    if (![operator uploadApplicationDataAtPath:xcappdata
                                      bundleID:bundleIdentifier
                                         error:error]) {
        return NO;
    }

    // Deliberately skipping error checking; error is ignorable.
    [[NSFileManager defaultManager] removeItemAtPath:xcappdata
                                               error:nil];

    return YES;
}

@end
