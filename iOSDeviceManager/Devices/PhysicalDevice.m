
#import "PhysicalDevice.h"
#import <FBControlCore/FBControlCore.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "Codesigner.h"
#import "AppUtils.h"
#import "CodesignIdentity.h"
#import "ConsoleWriter.h"
#import "Application.h"
#import "XCTestConfigurationPlist.h"
#import "XCAppDataBundle.h"
#import "DeviceUtils.h"

@interface PhysicalDevice()

@property (nonatomic, strong) FBDevice *fbDevice;

- (BOOL)installProvisioningProfileAtPath:(NSString *)path
                                   error:(NSError **)error;
@end

@implementation PhysicalDevice

+ (PhysicalDevice *)withID:(NSString *)uuid {
    PhysicalDevice* device = [[PhysicalDevice alloc] init];

    device.uuid = uuid;

    NSError *err;
    
    FBDeviceSet *deviceSet = [[DeviceUtils deviceSet:FBControlCoreGlobalConfiguration.defaultLogger ecidFilter:nil] await:&err];
    FBDevice *fbDevice = [deviceSet deviceWithUDID:uuid];

    if (!fbDevice) {
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
        
        if (![[self.fbDevice installApplicationWithPath:app.path] await:&error]) {
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

    NSError *err;
    
    if (![[self.fbDevice isApplicationInstalledWithBundleID:bundleID] await:&err]) {
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
    
    if (![[self.fbDevice uninstallApplicationWithBundleID:bundleID] await:&err]) {
        ConsoleWriteErr(@"Error uninstalling app %@: %@", bundleID, err);
        return iOSReturnStatusCodeInternalError;
    } else {
        return iOSReturnStatusCodeEverythingOkay;
    }
}

- (iOSReturnStatusCode)simulateLocationWithLat:(double)lat lng:(double)lng {

    NSError *error;
    if (![[self.fbDevice overrideLocationWithLongitude:lng latitude:lat] await:&error]){
        ConsoleWriteErr(@"Device %@ doesn't support location simulation", [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    if (error) {
        ConsoleWriteErr(@"Unable to set device location: %@", error);
        return iOSReturnStatusCodeInternalError;
    }

    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)stopSimulatingLocation {

    //the original functional is gone. That's how it implemented in idb
    NSError *error;
    //in the past it was [[self.fbDevice.dvtDevice token] stopSimulatingLocationWithError:&e];
    if (![[self.fbDevice overrideLocationWithLongitude:-122.147911 latitude:37.485023] await:&error]){
        ConsoleWriteErr(@"Device %@ doesn't support location simulation", [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    if (error) {
        ConsoleWriteErr(@"Unable to set device location: %@", error);
        return iOSReturnStatusCodeInternalError;
    }

    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)launchApp:(NSString *)bundleID {

    // Currently unsupported to have environment vars passed here.
    FBApplicationLaunchConfiguration *appLaunch = [[FBApplicationLaunchConfiguration alloc]
      initWithBundleID:bundleID
      bundleName:nil
      arguments:@[]
      environment:@{}
      waitForDebugger:NO
      io:FBProcessIO.outputToDevNull
      launchMode:FBApplicationLaunchModeRelaunchIfRunning];
    
    NSError *error = nil;
    
    if (![[self.fbDevice launchApplication:appLaunch] await:&error]) {
        ConsoleWriteErr(@"Failed launching app with bundleID: %@ due to error: %@", bundleID, error);
        return iOSReturnStatusCodeInternalError;
    }

    return iOSReturnStatusCodeEverythingOkay;
}

- (BOOL)launchApplicationWithConfiguration:(FBApplicationLaunchConfiguration *)configuration
                                     error:(NSError **)error {
    if ([[self.fbDevice launchApplication:configuration] await:error]){
        return YES;
    }
    else{
        return NO;
    }
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
    NSNumber *PID = [[self.fbDevice processIDWithBundleID:bundleIdentifier] await:&error];
    if ([PID intValue] < 1) {
        return 0;
    } else {
        return [PID intValue];
    }
}

- (BOOL)applicationIsRunning:(NSString *)bundleIdentifier {
    return [self processIdentifierForApplication:bundleIdentifier] != 0;
}

- (BOOL)terminateApplication:(NSString *)bundleIdentifier
                  wasRunning:(BOOL *)wasRunning {

    NSError *error = nil;
    
    NSNumber *PID = [[self.fbDevice processIDWithBundleID:bundleIdentifier] await:&error];
    if ([PID intValue] < 1) {
        if (wasRunning) { *wasRunning = NO; }
        return YES;
    } else {
        if (wasRunning) { *wasRunning = YES; }
    }
    
    if (![[self.fbDevice killApplicationWithBundleID:bundleIdentifier] await:&error]) {
        ConsoleWriteErr(@"Failed to terminate app %@\n  %@",
                        bundleIdentifier, [error localizedDescription]);
        return NO;
    } else {
        return YES;
    }
}

- (BOOL) isInstalled:(NSString *)bundleID withError:(NSError **)error {
    NSNumber * installed = [[self.fbDevice isApplicationInstalledWithBundleID:bundleID] await:error];
    return installed.boolValue;
}

- (iOSReturnStatusCode)isInstalled:(NSString *)bundleID {
    NSError *error;
    BOOL installed = [self isInstalled:bundleID withError:&error];

    if (error) {
        ConsoleWriteErr(@"Error checking if %@ is installed to %@: %@", bundleID, [self uuid], error);
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

//taken from idb. Couldn't been imported - should be looked.
- (FBFuture<NSArray<NSDictionary<NSString *, id> *> *> *)installedApplicationsData:(NSArray<NSString *> *)returnAttributes
{
  return [[self.fbDevice
    connectToDeviceWithPurpose:@"installed_apps"]
    onQueue:self.fbDevice.workQueue pop:^ FBFuture<NSDictionary<NSString *, NSDictionary<NSString *, id> *> *> * (id<FBDeviceCommands> device) {
      NSDictionary<NSString *, id> *options = @{
        @"ReturnAttributes": returnAttributes,
      };
      CFDictionaryRef applications;
      int status = device.calls.LookupApplications(
        device.amDeviceRef,
        (__bridge CFDictionaryRef _Nullable)(options),
        &applications
      );
      if (status != 0) {
        NSString *errorMessage = CFBridgingRelease(device.calls.CopyErrorText(status));
        return [[FBDeviceControlError
          describeFormat:@"Failed to get list of applications 0x%x (%@)", status, errorMessage]
          failFuture];
      }
      return [FBFuture futureWithResult:CFBridgingRelease(applications)];
    }];
}

//was removed in idb, but it's required at this moment
- (NSDictionary *)AMDinstalledApplicationWithBundleIdentifier:(NSString *)bundleID
{
  NSError *error = nil;
    
  NSArray<NSDictionary *> *apps = [[self installedApplicationsData: [PhysicalDevice applicationReturnAttributesDictionary]] await:&error];

  if (!apps){
    return nil;
  }

  for (NSDictionary *app in apps) {
    if ([app[@"CFBundleIdentifier"] isEqualToString:bundleID]) {
      return app;
    }
  }
  return nil;
}

//was removed in idb, but it's required at this moment
- (NSString *)containerPathForApplicationWithBundleID:(NSString *)bundleID error:(NSError **)error
{
    NSArray<NSDictionary *> *apps = [[self installedApplicationsData: [PhysicalDevice applicationReturnAttributesDictionary]] await:error];

    if (!apps){
      return nil;
    }

    for (NSDictionary *app in apps) {
        if ([app[@"CFBundleIdentifier"] isEqualToString:bundleID]) {
          return app[@"Container"];
        }
    }
    return nil;
}

//was removed in idb, but it's required at this moment
- (NSString *)applicationPathForApplicationWithBundleID:(NSString *)bundleID error:(NSError **)error
{
    NSArray<NSDictionary *> *apps = [[self installedApplicationsData: [PhysicalDevice applicationReturnAttributesDictionary]] await:error];

    if (!apps){
      return nil;
    }

    for (NSDictionary *app in apps) {
        if ([app[@"CFBundleIdentifier"] isEqualToString:bundleID]) {
          return app[@"Path"];
        }
    }
    return nil;
}

- (Application *)installedApp:(NSString *)bundleID {
    
    NSDictionary *plist;
    
    plist = [self AMDinstalledApplicationWithBundleIdentifier:bundleID];
    if (plist) {
        NSString *targetArch = self.fbDevice.architecture;
        //just to keep the old format
        NSSet *set = [NSSet setWithObject:targetArch];
        
        return [Application withBundleID:bundleID
                                   plist:plist
                           architectures:set];
    } else {
        return nil;
    }
}


- (iOSReturnStatusCode)uploadFile:(NSString *)filepath
                   forApplication:(NSString *)bundleID
                        overwrite:(BOOL)overwrite {
    
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
    
    
    
    id<FBFileCommands> commands = (id<FBFileCommands>) self.fbDevice;
    if (![commands conformsToProtocol:@protocol(FBFileCommands)]) {
        ConsoleWriteErr(@"uploadFile: Target doesn't conform to FBFileCommands protocol %@", e);
        return iOSReturnStatusCodeGenericFailure;
    }
    
    NSError *error = nil;
    BOOL success = [[[commands fileCommandsForContainerApplication:bundleID]
                     onQueue:self.fbDevice.asyncQueue pop:^(id<FBFileContainer> container) {
        return [container copyPathOnHost:[NSURL fileURLWithPath:filepath] toDestination:@"Documents"];
    }] await:&error] != nil;
    
    if (!success){
        ConsoleWriteErr(@"Unable to download app data for %@ to %@: %@",
                        bundleID,
                        xcappdataPath,
                        e);
        return iOSReturnStatusCodeInternalError;
    }
    
    [ConsoleWriter write:filepath];
    [ConsoleWriter write:dataBundle];
    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)downloadXCAppDataBundleForApplication:(NSString *)bundleIdentifier
                                                      toPath:(NSString *)path{
    
    NSError *e;
    
    id<FBFileCommands> commands = (id<FBFileCommands>) self.fbDevice;
    if (![commands conformsToProtocol:@protocol(FBFileCommands)]) {
        ConsoleWriteErr(@"downloadXCAppDataBundleForApplication: Target doesn't conform to FBFileCommands protocol %@", e);
        return iOSReturnStatusCodeGenericFailure;
    }
    
    BOOL success = [[[commands fileCommandsForContainerApplication:bundleIdentifier] onQueue:self.fbDevice.asyncQueue pop:^(id<FBFileContainer> container) {
        return [container copyItemInContainer:@"Documents" toDestinationOnHost:path];
        
    }] await:&e] != nil;
                   
    if (!success){
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

    NSError *e;
    
    id<FBFileCommands> commands = (id<FBFileCommands>) self.fbDevice;
    if (![commands conformsToProtocol:@protocol(FBFileCommands)]) {
        ConsoleWriteErr(@"downloadXCAppDataBundleForApplication: Target doesn't conform to FBFileCommands protocol %@", e);
        return iOSReturnStatusCodeGenericFailure;
    }
    
    BOOL success = [[[commands fileCommandsForContainerApplication:bundleIdentifier] onQueue:self.fbDevice.asyncQueue pop:^(id<FBFileContainer> container) {
        return [container copyPathOnHost:[NSURL fileURLWithPath:xcappdata] toDestination:@"Documents"];
    }] await:&e] != nil;
                   
    if (!success){
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

- (NSString *)containerPathForApplication:(NSString *)bundleID {
    return [self containerPathForApplicationWithBundleID:bundleID
                                                   error:nil];
}

- (NSString *)installPathForApplication:(NSString *)bundleID {
    return [self applicationPathForApplicationWithBundleID:bundleID
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
    id<FBFileCommands> commands = (id<FBFileCommands>) self.fbDevice;
    if (![commands conformsToProtocol:@protocol(FBFileCommands)]) {
        ConsoleWriteErr(@"downloadXCAppDataBundleForApplication: Target doesn't conform to FBFileCommands protocol %@", *error);
        return iOSReturnStatusCodeGenericFailure;
    }
    
    //copy provisioning profile
    BOOL success = [[[commands fileCommandsForProvisioningProfiles]
                     onQueue:self.fbDevice.asyncQueue pop:^(id<FBFileContainer> container) {
        //in this case (in case of FBFileContainer_ProvisioningProfile)
        //path toDestination means nothing in implementation
        return [container copyPathOnHost:[NSURL fileURLWithPath:path] toDestination:@""];
    }] await:error] != nil;
    
    return success;
}

- (BOOL)stageXctestConfigurationToTmpForRunner:(NSString *)pathToRunner
                                           AUT:(NSString *)pathToAUT
                                    deviceUDID:(NSString *)deviceUDID
                                         error:(NSError **)error {
    
    NSString *runnerName = [[pathToRunner lastPathComponent]
                            componentsSeparatedByString:@"."][0];
    NSString *appDataBundle = [runnerName stringByAppendingString:@".xcappdata"];
    
    NSString *directory = NSTemporaryDirectory();
    
    if (![XCAppDataBundle generateBundleSkeleton:directory
                                            name:appDataBundle
                                       overwrite:YES]) {
        return NO;
    }
    
    NSString *xcappdata = [directory stringByAppendingPathComponent:appDataBundle];
    
    Application *runnerApp = [Application withBundlePath:pathToRunner];
    NSString *runnerBundleId = [runnerApp bundleID];
    
    Application *AUTApp = [Application withBundlePath:pathToAUT];
    NSString *AUTBundleId = [AUTApp bundleID];
    
    
    NSString *runnerPath = [self applicationPathForApplicationWithBundleID:runnerBundleId error:error];
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    NSString *xctestBundlePath = [self xctestBundlePathForTestRunnerAtPath:runnerPath];
    
    NSString *xctestconfig = [XCTestConfigurationPlist plistWithXCTestInstallPath:xctestBundlePath
                                                                      AUTHostPath:pathToAUT
                                                              AUTBundleIdentifier:AUTBundleId
                                                                   runnerHostPath:pathToRunner
                                                           runnerBundleIdentifier:runnerBundleId
                                                                sessionIdentifier:uuid];
    
    NSString *tmpDirectory = [[xcappdata stringByAppendingPathComponent:@"AppData"]
                              stringByAppendingPathComponent:@"tmp"];
    
    
    NSString *runnerProductName = [[pathToRunner lastPathComponent]
                                   componentsSeparatedByString:@"-"][0];
    
    NSString *filename = [NSString stringWithFormat:@"%@-%@.xctestconfiguration",
                          runnerProductName, uuid];
    NSString *xctestconfigPath = [tmpDirectory stringByAppendingPathComponent:filename];
    
    NSData *plistData = [xctestconfig dataUsingEncoding:NSUTF8StringEncoding];
    
    if (![plistData writeToFile:xctestconfigPath
                     atomically:YES]) {
        ConsoleWriteErr(@"Could not create an .xctestconfiguration at path:\n  %@\n",
                        xctestconfigPath);
        return NO;
    }
    
    [[NSFileManager defaultManager] createDirectoryAtPath:@"xctestconfig"
                              withIntermediateDirectories:NO
                                               attributes:nil
                                                    error:nil];
    
    xctestconfigPath = [@"xctestconfig" stringByAppendingPathComponent:filename];
    if (![plistData writeToFile:xctestconfigPath
                     atomically:YES]) {
        ConsoleWriteErr(@"Could not create an .xctestconfiguration at path:\n  %@\n",
                        xctestconfigPath);
        return NO;
    }
    
    if ([self uploadXCAppDataBundle:xcappdata forApplication:runnerBundleId] != iOSReturnStatusCodeEverythingOkay){
        ConsoleWriteErr(@"Could not upload %@ to %@",
                        appDataBundle, runnerBundleId);
        return NO;
    }
    
    // Deliberately skipping error checking; error is ignorable.
    [[NSFileManager defaultManager] removeItemAtPath:xcappdata
                                               error:nil];
    
    ConsoleWrite(@"\n");
    ConsoleWrite(@" Runner: %@", runnerBundleId);
    ConsoleWrite(@"    AUT: %@", AUTBundleId);
    ConsoleWrite(@"Session: %@", uuid);
    
    NSString *containerPath = [self containerPathForApplication:runnerBundleId];
    NSString *installedPath = [[containerPath stringByAppendingPathComponent:@"tmp"]
                               stringByAppendingPathComponent:filename];
    ConsoleWrite(@"   Path: %@", xctestconfigPath);
    
    ConsoleWrite(@"\n-a /Developer/usr/lib/libXCTTargetBootstrapInject.dylib \\\n"
                 "-b %@ \\\n"
                 "-t %@ \\\n"
                 "-s %@ \\\n"
                 "-u %@ \\\n"
                 "-c %@\n",
                 runnerBundleId, AUTBundleId, uuid, deviceUDID, installedPath);
    
    return YES;
}

- (id<FBControlCoreLogger>)info {
    level = FBControlCoreLogLevelInfo;
    return self;
}

- (id<FBControlCoreLogger>)debug {
    level = FBControlCoreLogLevelDebug;
    return self;
}

- (id<FBControlCoreLogger>)error {
    level = FBControlCoreLogLevelError;
    return self;
}

- (nonnull id<FBControlCoreLogger>)withDateFormatEnabled:(BOOL)enabled { 
    return self;
}


- (nonnull id<FBControlCoreLogger>)withName:(nonnull NSString *)name { 
    return self;
}


- (id<FBControlCoreLogger>)onQueue:(dispatch_queue_t)queue {
    return self;
}

- (id<FBControlCoreLogger>)withPrefix:(NSString *)prefix {
    return self;
}

- (void)debuggerAttached { 
    [self log:@"Debugger attached"];
}

- (void)didBeginExecutingTestPlan {
}

- (void)didCrashDuringTest:(nonnull NSError *)error { 
    [self logFormat:@"didCrashDuringTest: %@", error];
}

- (void)didFinishExecutingTestPlan { 
    //TODO:
}

- (void)finishedWithSummary:(nonnull FBTestManagerResultSummary *)summary { 
    // didFinishExecutingTestPlan should be used to signify completion instead
}

- (void)handleExternalEvent:(nonnull NSString *)event { 
    [self logFormat:@"handleExternalEvent: %@", event];
}

- (BOOL)printReportWithError:(NSError *__autoreleasing  _Nullable * _Nullable)error { 
    [self logFormat:@"printReportWithError: %@", *error];
    return NO;
}

- (void)processUnderTestDidExit { 
    //TODO:
}

- (void)processWaitingForDebuggerWithProcessIdentifier:(pid_t)pid { 
    [self logFormat:@"Tests waiting for debugger. To debug run: lldb -p %d", pid];
}

- (void)testCaseDidFailForTestClass:(nonnull NSString *)testClass method:(nonnull NSString *)method withMessage:(nonnull NSString *)message file:(nullable NSString *)file line:(NSUInteger)line { 
    [self logFormat:@"Got failure info for %@/%@", testClass, method];
}

- (void)testCaseDidFinishForTestClass:(nonnull NSString *)testClass method:(nonnull NSString *)method withStatus:(FBTestReportStatus)status duration:(NSTimeInterval)duration logs:(nullable NSArray<NSString *> *)logs { 
    //TODO:
}

- (void)testCaseDidStartForTestClass:(nonnull NSString *)testClass method:(nonnull NSString *)method { 
    //TODO:
}

- (void)testHadOutput:(nonnull NSString *)output { 
    [self logFormat:@"testHadOutput: %@", output];
}

- (void)testSuite:(nonnull NSString *)testSuite didStartAt:(nonnull NSString *)startTime { 
    //TODO:
}

@synthesize level;

@end
