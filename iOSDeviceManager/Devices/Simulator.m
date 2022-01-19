
#import "Simulator.h"
#import "AppUtils.h"
#import "Codesigner.h"
#import "ConsoleWriter.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "XCTestConfigurationPlist.h"
#import "XCAppDataBundle.h"
#import <FBControlCore/FBControlCore.h>
#import <CoreSimulator/SimDevice.h>
#import <CoreSimulator/SimDeviceBootInfo.h>

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@interface Simulator()

@property (nonatomic, strong) FBSimulator *fbSimulator;

+ (FBSimulatorLifecycleCommands *)lifecycleCommandsWithFBSimulator:(FBSimulator *)fbSimulator;
+ (FBSimulatorApplicationCommands *)applicationCommandsWithFBSimulator:(FBSimulator *)fbSimulator;
- (FBiOSTargetState)state;
- (NSString *)stateString;
- (BOOL)waitForSimulatorState:(FBiOSTargetState)state
                      timeout:(NSTimeInterval)timeout;
- (BOOL)waitForBootableState:(NSError *__autoreleasing *)error;
@end

@implementation Simulator

static const FBSimulatorControl *_control;

+ (void)initialize {
    FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration
                                                      configurationWithDeviceSetPath:nil
                                                      logger:nil
                                                      reporter:nil];

    NSError *error;
    _control = [FBSimulatorControl withConfiguration:configuration error:&error];
    if (error) {
        ConsoleWriteErr(@"Error creating FBSimulatorControl: %@", error);
        abort();
    }
}

+ (Simulator *)withID:(NSString *)uuid {
    Simulator* simulator = [[Simulator alloc] init];

    simulator.uuid = uuid;

    FBSimulatorSet *sims = _control.set;
    if (!sims) {
        ConsoleWriteErr(@"Unable to retrieve simulators");
        return nil;
    }

    FBSimulator *simulatorFromUUID = [sims simulatorWithUDID:uuid];
    if (!simulatorFromUUID) {
        ConsoleWriteErr(@"No simulators found for ID %@", uuid);
        return nil;
    }

    simulator.fbSimulator = simulatorFromUUID;

    return simulator;
}

+ (FBSimulatorLifecycleCommands *)lifecycleCommandsWithFBSimulator:(FBSimulator *)simulator {
    FBSimulatorLifecycleCommands *lifecycleCommands = [FBSimulatorLifecycleCommands commandsWithTarget:simulator];
    [lifecycleCommands disconnectWithTimeout:5 logger:nil];
    return [FBSimulatorLifecycleCommands commandsWithTarget:simulator];
}

+ (FBSimulatorApplicationCommands *)applicationCommandsWithFBSimulator:(FBSimulator *)simulator {
    return [FBSimulatorApplicationCommands commandsWithTarget:simulator];
}

/// @return NSURL with path to Simulator app.
+ (NSURL *)simulatorAppURL {
    NSString *path = [[FBXcodeConfiguration simulatorApp] path];
    return [NSURL fileURLWithPath:path];
}

//taken from idb. Couldn't been imported - should be tracked.
+ (FBFuture<NSNull *> *)performBootVerification:(FBSimulator *)simulator
{
  SimDeviceBootInfo *bootInfo = simulator.device.bootStatus;
  if (!bootInfo) {
    return [[FBSimulatorError
      describeFormat:@"No bootInfo for %@", simulator]
      failFuture];
  }
//  [self updateBootInfo:bootInfo];
  if (bootInfo.isTerminalStatus == NO) {
    return [[FBSimulatorError
      describeFormat:@"Not terminal status, status is %@", bootInfo]
      failFuture];
  }
  return FBFuture.empty;
}

+ (BOOL)waitForSimulatorAppServices:(FBSimulator *)fbSimulator {
    
    BOOL success = NO;
    
    return [NSRunLoop.currentRunLoop spinRunLoopWithTimeout:120 untilTrue:^BOOL{
        NSError *error = nil;

        // No services running yet.
        if (![[Simulator performBootVerification:fbSimulator] await:&error]) {
            return NO;
        } else {
            return YES;
        }
    }];

    return success;
}

+ (iOSReturnStatusCode)launchSimulator:(Simulator *)simulator {
    NSError *error = nil;
    if ([simulator waitForBootableState:&error]) {

        error = nil;
        BOOL success = [simulator launchSimulatorApp:&error];
        if (success) {
            return iOSReturnStatusCodeEverythingOkay;
        } else {
            ConsoleWriteErr(@"Could not launch simulator.");
            if (error) {
                ConsoleWriteErr(@"%@", [error localizedDescription]);
            }
            return iOSReturnStatusCodeGenericFailure;
        }
    } else {
        ConsoleWriteErr(@"Could not launch simulator");
        if (error) {
            ConsoleWriteErr(@"%@", [error localizedDescription]);
        }
        return iOSReturnStatusCodeGenericFailure;
    }
    return iOSReturnStatusCodeEverythingOkay;
}

+ (iOSReturnStatusCode)killSimulatorApp {
    NSString *bundleIdentifier = @"com.apple.iphonesimulator";
    NSArray<NSRunningApplication *> *applications;
    applications = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier];

    if (applications.count > 0) {
        for (NSRunningApplication *application in applications) {
            [application terminate];

            BOOL termed = [NSRunLoop.currentRunLoop spinRunLoopWithTimeout:2 untilTrue:^BOOL{
                return application.terminated;
            }];

            if (!termed) {
                [application forceTerminate];
            }

            termed = [NSRunLoop.currentRunLoop spinRunLoopWithTimeout:2 untilTrue:^BOOL{
                return application.terminated;
            }];

            if (!termed) {
                ConsoleWriteErr(@"Could not terminate Simulator.app");
                return iOSReturnStatusCodeGenericFailure;
            }
        }
    }

    FBSimulatorSet *simulators = _control.set;
    NSArray <FBSimulator *> *results = [simulators allSimulators];
    for (FBSimulator *simulator in results) {
        Simulator *sim = [Simulator withID:simulator.udid];
        if (![sim shutdown]) {
            ConsoleWriteErr(@"Could not shutdown simulator: %@", simulator);
            return iOSReturnStatusCodeGenericFailure;
        }
    }
    return iOSReturnStatusCodeEverythingOkay;
}

+ (iOSReturnStatusCode)eraseSimulator:(Simulator *)simulator {
    [Simulator killSimulatorApp];
    if (![simulator waitForSimulatorState:FBiOSTargetStateShutdown timeout:30]) {
        ConsoleWriteErr(@"Error: Could not shutdown simulator: %@", simulator);
        return iOSReturnStatusCodeInternalError;
    }

    NSError *error = nil;
    if (![[simulator.fbSimulator erase] await:&error]){
        ConsoleWriteErr(@"Error: %@", [error localizedDescription]);
        return iOSReturnStatusCodeInternalError;
    }

    return iOSReturnStatusCodeEverythingOkay;
}

- (FBiOSTargetState)state {
    return self.fbSimulator.state;
}

- (NSString *)stateString {
    return self.fbSimulator.stateString;
}

- (BOOL)waitForSimulatorState:(FBiOSTargetState)state
                      timeout:(NSTimeInterval)timeout {
    NSError* error = nil;

    if ([[[self.fbSimulator resolveState:state]
          timeout:timeout waitingFor:@"Simulator to resolve state %@", FBiOSTargetStateStringFromState(state).lowercaseString] await:&error]) {
        return YES;
    }
    else{
        return NO;
    }
}

- (BOOL)waitForBootableState:(NSError *__autoreleasing *)error {

    NSTimeInterval waitTimeout = 30;
    NSString *message;
    NSString *messageFmt = @"Simulator never finished %@ after %@ seconds";

    switch (self.state) {
        case FBiOSTargetStateBooted: { return YES; }
        case FBiOSTargetStateShutdown: { return YES; }

        case FBiOSTargetStateCreating: {
            if ([self waitForSimulatorState:FBiOSTargetStateShutdown
                                    timeout:waitTimeout]) {
                return YES;
            } else {
                if (error) {
                    message = [NSString stringWithFormat:messageFmt,
                               @"creating", @(waitTimeout)];
                    *error = [NSError errorWithDomain:@"iOSDeviceManager"
                                                 code:iOSReturnStatusCodeInternalError
                                             userInfo:@{
                                                        NSLocalizedDescriptionKey : message
                                                        }];
                }
                return NO;
            }
        }

        case FBiOSTargetStateBooting: {
            if ([self waitForSimulatorState:FBiOSTargetStateBooted
                                    timeout:waitTimeout]) {
                return YES;
            } else {
                if (error) {
                    message = [NSString stringWithFormat:messageFmt,
                               @"booting", @(waitTimeout)];
                    *error = [NSError errorWithDomain:@"iOSDeviceManager"
                                                 code:iOSReturnStatusCodeInternalError
                                             userInfo:@{
                                                        NSLocalizedDescriptionKey : message
                                                        }];
                }
                return NO;
            }
        }

        case FBiOSTargetStateShuttingDown: {
            if ([self waitForSimulatorState:FBiOSTargetStateShutdown
                                    timeout:waitTimeout]) {
                return YES;
            } else {
                if (error) {
                    message = [NSString stringWithFormat:messageFmt,
                               @"shutting down", @(waitTimeout)];
                    *error = [NSError errorWithDomain:@"iOSDeviceManager"
                                                 code:iOSReturnStatusCodeInternalError
                                             userInfo:@{
                                                        NSLocalizedDescriptionKey : message
                                                        }];
                }
                return NO;
            }
        }

        default: {
            if (error) {
                message = [NSString stringWithFormat:@"Could not boot simulator from this state: %@",
                           self.stateString];
                *error = [NSError errorWithDomain:@"iOSDeviceManager"
                                             code:iOSReturnStatusCodeInternalError
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey : message
                                                    }];
            }
            return NO;
        }
    }
}

- (BOOL)boot {
    NSError *error = nil;
    if (![self waitForBootableState:&error]) {
        ConsoleWriteErr(@"Could not boot simulator");
        if (error) {
            ConsoleWriteErr(@"%@", [error localizedDescription]);
        }
        return NO;
    }

    FBiOSTargetState state = self.state;
    if (state == FBiOSTargetStateBooted || state == FBiOSTargetStateBooting) {
        if (![self waitForSimulatorState:FBiOSTargetStateBooted
                                 timeout:120]) {
            ConsoleWriteErr(@"Could not boot simulator");
            return NO;
        } else {
            return YES;
        }
    } else {

        if ([Simulator launchSimulator:self] != iOSReturnStatusCodeEverythingOkay){
            ConsoleWriteErr(@"Could not boot simulator");
            if (error) {
                ConsoleWriteErr(@"%@", [error localizedDescription]);
            }
            return NO;
        } else {
            if (![self waitForSimulatorState:FBiOSTargetStateBooted
                                     timeout:120]) {
                ConsoleWriteErr(@"Could not boot simulator");
                return NO;
            }
            return YES;
        }
    }
}

- (BOOL)launchSimulatorApp:(NSError **)error {
    NSArray *arguments = @[@"--args",
                           @"-CurrentDeviceUDID", self.uuid,
                           @"-ConnectHardwareKeyboard", @"0",
                           @"-DeviceBootTimeout", @"120",
                           @"LAUNCHED_WITH_IOS_DEVICE_MANAGER"
                           ];

    NSWorkspaceOpenConfiguration *configuration = [NSWorkspaceOpenConfiguration configuration];
    configuration.arguments = arguments;
    configuration.hides = YES;
    
    BOOL result = NO;

    for (int attemptsToLaunch = 0; attemptsToLaunch < 3; attemptsToLaunch++) {
        NSURL *url = [Simulator simulatorAppURL];
        [[NSWorkspace sharedWorkspace] openApplicationAtURL:url
                                              configuration:configuration
                                          completionHandler:^(NSRunningApplication *application, NSError *error) {
            if (application != NULL) {
                pid_t pid = [application processIdentifier];
                FBProcessFetcher *fetcher = [FBProcessFetcher new];
                FBProcessInfo *info = [fetcher processInfoFor:pid];

                if (![info.arguments containsObject:self.uuid]) {
                    ConsoleWriteErr(@"Running simulator udid does not match %@", self.uuid);
                    ConsoleWriteErr(@"Restarting simulator...");
                    [Simulator killSimulatorApp];
                }
            } else {
                ConsoleWriteErr(@"Could not launch Simulator.app for %@", self.fbSimulator);
            }
        }];

        if(![Simulator waitForSimulatorAppServices:self.fbSimulator]) {
            ConsoleWriteErr(@"Timed out waiting for all simulator services to start");
            result = NO;
        } else {
            result = YES;
            break;
        }
    }
    if (!result) {
        ConsoleWriteErr(@"Could not launch Simulator.app in 3 attempts.");
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)shutdown {
    NSError *error = nil;
    SimDevice *simDevice = [self.fbSimulator device];
    if (self.state == FBiOSTargetStateShutdown) { return YES; }

    if (self.state != FBiOSTargetStateShuttingDown ||
        self.state == FBiOSTargetStateShutdown) {
        if (![simDevice shutdownWithError:&error]) {
            ConsoleWriteErr(@"Could not shutdown simulator");
            if (error) {
                ConsoleWriteErr(@"%@", [error localizedDescription]);
            }
            return NO;
        }
    }

    if (![self waitForSimulatorState:FBiOSTargetStateShutdown timeout:30]) {
        ConsoleWriteErr(@"Timed out waiting for simulator to shutdown after 30 seconds");
        return NO;
    }

    return YES;
}

- (iOSReturnStatusCode)installApp:(Application *)app
                    mobileProfile:(MobileProfile *)profile
                 codesignIdentity:(CodesignIdentity *)codesignID
                resourcesToInject:(NSArray<NSString *> *)resourcePaths
                   forceReinstall:(BOOL)forceReinstall {

    if (![self boot]) {
        ConsoleWriteErr(@"Cannot install %@ on Simulator %@ because the device could not "
                        "be booted", app.bundleID, [self fbSimulator]);
        return iOSReturnStatusCodeGenericFailure;
    }

    BOOL needsToInstall = YES;
    Application *installedApp = [self installedApp:app.bundleID];

    if (!forceReinstall && installedApp) {
        iOSReturnStatusCode statusCode = iOSReturnStatusCodeEverythingOkay;
        needsToInstall = [self shouldUpdateApp:app
                                  installedApp:installedApp
                                    statusCode:&statusCode];
        if (statusCode != iOSReturnStatusCodeEverythingOkay) {
            // #shouldUpdateApp:installedApp:statusCode: will log failure messages
            return statusCode;
        }
    }

    if (needsToInstall || forceReinstall) {
        // Uninstall app to avoid application-identifier entitlement mismatch
        [self uninstallApp:app.bundleID];

        [Codesigner resignApplication:app
              withProvisioningProfile:nil
                 withCodesignIdentity:nil
                    resourcesToInject:resourcePaths];

        FBSimulatorApplicationCommands *applicationCommands;
        applicationCommands = [Simulator
                               applicationCommandsWithFBSimulator:self.fbSimulator];

        NSUInteger tries = 5;
        NSError *error = nil;
        BOOL success = NO;
        for (NSUInteger try = 1; try < tries; try++) {
            error = nil;
            
            if ([[applicationCommands installApplicationWithPath:app.path] await:&error]){
                ConsoleWrite(@"Installed application on %@ of %@ attempts",
                             @(try), @(tries));
                success = YES;
                break;
            }

            if ([[error description]
                 containsString:@"This app could not be installed at this time"]) {
                ConsoleWrite(@"Failed to install the app on attempt %@ of %@",
                             @(try), @(tries));
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 2.0, false);
            } else {
                // Any other error
                ConsoleWriteErr(@"Error installing application: %@", error);
                break;
            }
        }

        if (success) {
            ConsoleWrite(@"Installed %@ version: %@ / %@ to %@", app.bundleID,
                         app.bundleVersion, app.bundleShortVersion, [self uuid]);
            return iOSReturnStatusCodeEverythingOkay;
        } else {
            return iOSReturnStatusCodeGenericFailure;
        }
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

    // uninstalling an app when the Simulator.app is running will cause the
    // app bundle to be removed, but CoreSimulator will report the app is
    // still installed.
    [Simulator killSimulatorApp];

    if (![self boot]) {
        ConsoleWriteErr(@"Cannot uninstall app %@ from %@ because the Simulator"
                        " failed to boot", bundleID, [self fbSimulator]);
        return iOSReturnStatusCodeGenericFailure;
    }

    if (![self isInstalled:bundleID withError:nil]) {
        ConsoleWriteErr(@"App %@ is not installed on %@", bundleID, [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    FBSimulatorApplicationCommands *applicationCommands;
    applicationCommands = [Simulator applicationCommandsWithFBSimulator:self.fbSimulator];

    NSError *error = nil;
    if (![[applicationCommands uninstallApplicationWithBundleID:bundleID] await:&error]) {
        ConsoleWriteErr(@"Error uninstalling app: %@", error);
        return iOSReturnStatusCodeInternalError;
    } else {
        if ([self isInstalled:bundleID withError:nil]) {
            ConsoleWrite(@"Rebooting device to reset installed-apps database");
            [self shutdown];
            [self boot];

            if ([self isInstalled:bundleID withError:&error]){
                ConsoleWriteErr(@"Could not uninstall app %@", error);
                return iOSReturnStatusCodeInternalError;
            }
        }
        ConsoleWrite(@"Application %@ was uninstalled", bundleID);
        return iOSReturnStatusCodeEverythingOkay;
    }
}

- (iOSReturnStatusCode)simulateLocationWithLat:(double)lat
                                           lng:(double)lng {

    // Set the Location to a default location, when launched directly.
    // This is effectively done by Simulator.app by a NSUserDefault with for the
    // 'LocationMode', even when the location is 'None'. If the Location is set on the
    // Simulator, then CLLocationManager will behave in a consistent manner inside
    // launched Applications.
    if (![self boot]) {
        ConsoleWriteErr(@"Cannot set the location on the %@ simulator because the device "
                        "would not boot",
                        [self fbSimulator]);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *error = nil;
    if (![[self.fbSimulator overrideLocationWithLongitude:lng latitude:lat] await:&error]){
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
    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)launchApp:(NSString *)bundleID {
    NSError *error = nil;

    if (![self isInstalled:bundleID withError:&error]) {
        ConsoleWriteErr(@"Application %@ is not installed on simulator %@",
                        bundleID, self.uuid);
        if (error) {
            ConsoleWriteErr(@"%@", [error localizedDescription]);
        }
        return iOSReturnStatusCodeGenericFailure;
    }

    if (![self launchSimulatorApp:&error]) {
        ConsoleWriteErr(@"Could not launch the Simulator.app.");
        if (error) {
            ConsoleWriteErr(@"%@", [error localizedDescription]);
        }
        return iOSReturnStatusCodeGenericFailure;
    }

    FBApplicationLaunchConfiguration *launchConfig = [[FBApplicationLaunchConfiguration alloc]
                                                      initWithBundleID:bundleID
                                                      bundleName:nil
                                                      arguments:@[]
                                                      environment:@{}
                                                      waitForDebugger:NO
                                                      io:FBProcessIO.outputToDevNull
                                                      launchMode:FBApplicationLaunchModeRelaunchIfRunning];
    

    if ([[self.fbSimulator launchApplication:launchConfig] await:&error]) {
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        ConsoleWriteErr(@"Could not launch app %@ on simulator %@",
                        bundleID, self.uuid);
        if (error) {
            ConsoleWriteErr(@"%@", [error localizedDescription]);
        }
        return iOSReturnStatusCodeInternalError;
    }
}

- (BOOL)launchApplicationWithConfiguration:(FBApplicationLaunchConfiguration *)configuration
                                     error:(NSError **)error {
    return [[self.fbSimulator launchApplication:configuration] await:error] != nil;
}

- (iOSReturnStatusCode)killApp:(NSString *)bundleID {
    NSError *error = nil;
    
    if (![[self.fbSimulator killApplicationWithBundleID:bundleID] await:&error]){
        return iOSReturnStatusCodeFalse;
    }
    else{
        return iOSReturnStatusCodeEverythingOkay;
    }
}

- (BOOL)isInstalled:(NSString *)bundleID withError:(NSError **)error {

    NSDictionary *installedApps = [self.fbSimulator.device installedAppsWithError:error];
    if (installedApps[bundleID]) {
        return YES;
    } else {
        return NO;
    }
}

- (iOSReturnStatusCode)isInstalled:(NSString *)bundleID {

    NSError *error = nil;
    if (![self boot]) {
        ConsoleWriteErr(@"Cannot check for installed application"
                        "%@ on Simulator %@ because the device could not "
                        "be booted", bundleID, self.fbSimulator);
        return iOSReturnStatusCodeInternalError;
    }
    BOOL installed = [self isInstalled:bundleID withError:&error];

    if (installed) {
        [ConsoleWriter write:@"true"];
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        [ConsoleWriter write:@"false"];
        return iOSReturnStatusCodeFalse;
    }
}

- (Application *)installedApp:(NSString *)bundleID {
    NSError *error = nil;
    FBInstalledApplication *installedApp;
    installedApp = [[self.fbSimulator installedApplicationWithBundleID:bundleID] await:&error];
    if (!installedApp) {
        return nil;
    } else {
        return [Application withBundlePath:installedApp.bundle.path];
    }
}

- (iOSReturnStatusCode)uploadFile:(NSString *)filepath
                   forApplication:(NSString *)bundleID
                        overwrite:(BOOL)overwrite {

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:filepath]) {
        ConsoleWriteErr(@"File does not exist: %@", filepath);
        return iOSReturnStatusCodeInvalidArguments;
    }

    NSString *containerPath = [self containerPathForApplication:bundleID];
    if (!containerPath) {
        ConsoleWriteErr(@"Unable to find container path for app %@ on device %@", bundleID, [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSString *documentsDir = [containerPath stringByAppendingPathComponent:@"Documents"];
    NSString *filename = [filepath lastPathComponent];
    NSString *dest = [documentsDir stringByAppendingPathComponent:filename];
    NSError *e;

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

    [ConsoleWriter write:dest];
    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)downloadXCAppDataBundleForApplication:(NSString *)bundleID
                                                      toPath:(NSString *)path {
    NSError *e;
    NSString *containerPath = [self containerPathForApplication:bundleID];
    if (!containerPath) {
        ConsoleWriteErr(@"Unable to find container path for app %@ on device %@",
                        bundleID, [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }
    if (![[NSFileManager defaultManager] removeItemAtPath:path error:&e]) {
        ConsoleWriteErr(@"Error: %@", e.localizedDescription);
        return iOSReturnStatusCodeInternalError;
    }
    if (![[NSFileManager defaultManager] copyItemAtPath:containerPath
                                                 toPath:path
                                                  error:&e]) {
        ConsoleWriteErr(@"Unable to copy xcappdata for app %@ on device %@\n"
                        "Error: %@",
                        bundleID, [self uuid], e.localizedDescription);
        return iOSReturnStatusCodeGenericFailure;
    }
    return iOSReturnStatusCodeEverythingOkay;
}

- (iOSReturnStatusCode)uploadXCAppDataBundle:(NSString *)xcappdata
                              forApplication:(NSString *)bundleIdentifier {

    if (![XCAppDataBundle isValid:xcappdata]) {
        return iOSReturnStatusCodeGenericFailure;
    }

    NSString *containerPath = [self containerPathForApplication:bundleIdentifier];
    if (!containerPath) {
        ConsoleWriteErr(@"Unable to find container path for app %@ on device %@",
                        bundleIdentifier, [self uuid]);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSArray *sources = [XCAppDataBundle sourceDirectoriesForSimulator:xcappdata];
    NSArray *targets = @[
                         [containerPath stringByAppendingPathComponent:@"Documents"],
                         [containerPath stringByAppendingPathComponent:@"Library"],
                         [containerPath stringByAppendingPathComponent:@"tmp"]
                         ];

    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    for (NSUInteger index = 0; index < [sources count]; index++) {
        NSString *target = targets[index];
        if ([fileManager fileExistsAtPath:target isDirectory:nil]) {
            if (![fileManager removeItemAtPath:target error:&error]) {
                ConsoleWriteErr(@"Cannot remove existing file:\n  %@\n"
                                "because of error:\n  %@\n",
                                "while trying to upload xcappdata",
                                target, [error localizedDescription]);
                return iOSReturnStatusCodeGenericFailure;
            }
        }

        NSString *source = sources[index];

        if (![fileManager copyItemAtPath:source toPath:target error:&error]) {
            ConsoleWriteErr(@"Failed to upload xcappdata:\n  %@\n"
                            "while trying to copy:\n  %@\n"
                            "to:\n  %@",
                            xcappdata, source, target);
        }
    }

    return iOSReturnStatusCodeEverythingOkay;
}

+ (FBBundleDescriptor *)app:(NSString *)appPath {
    NSError *error = nil;

    FBBundleDescriptor *app = [FBBundleDescriptor bundleFromPath:appPath error:&error];
    
    if (!app) {
        ConsoleWriteErr(@"Error creating SimulatorApplication for path %@: %@",
                        appPath, [error localizedDescription]);
        return nil;
    }
    return app;
}

+ (FBApplicationLaunchConfiguration *)testRunnerLaunchConfig:(NSString *)testRunnerPath {
    FBBundleDescriptor *application = [self app:testRunnerPath];

    return [[FBApplicationLaunchConfiguration alloc]
            initWithBundleID:application.identifier
            bundleName:application.name
            arguments:@[]
            environment:@{}
            waitForDebugger:NO
            io:FBProcessIO.outputToDevNull
            launchMode:FBApplicationLaunchModeRelaunchIfRunning];
}

+ (BOOL)iOS_GTE_9:(NSString *)versionString {
    NSArray <NSString *> *components = [versionString componentsSeparatedByString:@" "];
    if (components.count < 2) {
        DDLogWarn(@"Unparseable version string: %@", versionString);
        return YES;
    }
    NSString *versionNumberString = components[1];
    float versionNumber = [versionNumberString floatValue];
    if (versionNumber < 9) {
        ConsoleWriteErr(@"The simulator you selected has %@ installed. \n\
                        %@ is not valid for testing. \n\
                        Tests can not be run on iOS less than 9.0",
                        versionString,
                        versionString);
        return NO;
    }
    DDLogInfo(@"%@ is valid for testing.", versionString);
    return YES;
}


+ (FBSimulator *)simulatorWithConfiguration:(FBSimulatorConfiguration *)configuration {
    NSError *error = nil;
    FBSimulator *simulator = [[_control.set createSimulatorWithConfiguration:configuration] await:&error];

    if (error) {
        ConsoleWriteErr(@"Error obtaining simulator: %@", error);
    }
    return simulator;
}

#pragma mark - Test Reporter Methods

- (void)testManagerMediatorDidBeginExecutingTestPlan:(FBTestManagerAPIMediator *)mediator {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
                  testSuite:(NSString *)testSuite
                 didStartAt:(NSString *)startTime {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator testCaseDidFinishForTestClass:(NSString *)testClass method:(NSString *)method withStatus:(FBTestReportStatus)status duration:(NSTimeInterval)duration {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator testCaseDidFailForTestClass:(NSString *)testClass method:(NSString *)method withMessage:(NSString *)message file:(NSString *)file line:(NSUInteger)line {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
testBundleReadyWithProtocolVersion:(NSInteger)protocolVersion
             minimumVersion:(NSInteger)minimumVersion {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
testCaseDidStartForTestClass:(NSString *)testClass
                     method:(NSString *)method {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediator:(FBTestManagerAPIMediator *)mediator
        finishedWithSummary:(FBTestManagerResultSummary *)summary {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (void)testManagerMediatorDidFinishExecutingTestPlan:(FBTestManagerAPIMediator *)mediator {
    DDLogInfo(@"[%@ %@]", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    self.testingComplete = YES;
}

#pragma mark - FBControlCoreLogger
- (id<FBControlCoreLogger>)log:(NSString *)string {
    DDLogInfo(@"%@", string);
    return self;
}

- (id<FBControlCoreLogger>)logFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2) {
    va_list args;
    va_start(args, format);
    id str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    DDLogInfo(@"%@", str);
    return self;
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

- (id<FBControlCoreLogger>)onQueue:(dispatch_queue_t)queue {
    return self;
}

- (id<FBControlCoreLogger>)withPrefix:(NSString *)prefix {
    return self;
}

- (NSString *)containerPathForApplication:(NSString *)bundleID {
    NSFileManager *fm = [NSFileManager defaultManager];

    NSString *appDataPath = [[[[[[[[[NSHomeDirectory()
                                     stringByAppendingPathComponent:@"Library"]
                                    stringByAppendingPathComponent:@"Developer"]
                                   stringByAppendingPathComponent:@"CoreSimulator"]
                                  stringByAppendingPathComponent:@"Devices"]
                                 stringByAppendingPathComponent:[self uuid]]
                                stringByAppendingPathComponent:@"data"]
                               stringByAppendingPathComponent:@"Containers"]
                              stringByAppendingPathComponent:@"Data"]
                             stringByAppendingPathComponent:@"Application"];

    NSArray *bundleFolders = [fm contentsOfDirectoryAtPath:appDataPath error:nil];

    for (id bundleFolder in bundleFolders) {
        NSString *bundleFolderPath = [appDataPath stringByAppendingPathComponent:bundleFolder];
        NSString *plistFile = [bundleFolderPath
                               stringByAppendingPathComponent:@".com.apple.mobile_container_manager.metadata.plist"];

        if ([fm fileExistsAtPath:plistFile]) {
            NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistFile];
            if ([plist[@"MCMMetadataIdentifier"] isEqualToString:bundleID]) {
                return bundleFolderPath;
            }
        }
    }

    return nil;
}

- (NSString *)installPathForApplication:(NSString *)bundleID {
    FBInstalledApplication *installedApp;
    NSError *error = nil;
    installedApp = [[self.fbSimulator installedApplicationWithBundleID:bundleID] await:&error];
    return installedApp.bundle.path;
}

- (BOOL)stageXctestConfigurationToTmpForRunner:(NSString *)runnerBundleIdentifier
                                           AUT:(NSString *)AUTBundleIdentifier
                                         error:(NSError **)error {
    NSString *runnerInstalledPath = [self installPathForApplication:runnerBundleIdentifier];
    NSString *xctestBundlePath = [self xctestBundlePathForTestRunnerAtPath:runnerInstalledPath];
    NSString *AUTInstalledPath = [self installPathForApplication:AUTBundleIdentifier];
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    NSString *xctestconfig = [XCTestConfigurationPlist plistWithXCTestInstallPath:xctestBundlePath
                                                                      AUTHostPath:AUTInstalledPath
                                                              AUTBundleIdentifier:AUTBundleIdentifier
                                                                   runnerHostPath:runnerInstalledPath
                                                           runnerBundleIdentifier:runnerBundleIdentifier
                                                                sessionIdentifier:uuid];

    NSString *containerPath = [self containerPathForApplication:runnerBundleIdentifier];
    NSString *tmpDirectory = [containerPath stringByAppendingPathComponent:@"tmp"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:tmpDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:tmpDirectory
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:error]) {
            return NO;
        }
    }

    NSString *filename = [uuid stringByAppendingString:@".xctestconfiguration"];
    NSString *xctestconfigPath = [tmpDirectory stringByAppendingPathComponent:filename];

    NSArray *tmpDirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tmpDirectory
                                                                                  error:error];
    if (!tmpDirContents) {
        return NO;
    }

    for (NSString *fileName in tmpDirContents) {
        if ([@"xctestconfiguration" isEqualToString:[fileName pathExtension]]) {
            NSString *path = [tmpDirectory stringByAppendingPathComponent:fileName];
            if (![[NSFileManager defaultManager] removeItemAtPath:path
                                                            error:error]) {
                return NO;
            }

        }
    }

    NSData *plistData = [xctestconfig dataUsingEncoding:NSUTF8StringEncoding];

    if (![plistData writeToFile:xctestconfigPath
                     atomically:YES]) {
        ConsoleWriteErr(@"Could not create an .xctestconfiguration at path:\n  %@\n",
                        xctestconfigPath);
        return NO;
    }

    ConsoleWrite(@"Runner: %@", runnerBundleIdentifier);
    ConsoleWrite(@"AUT: %@", AUTBundleIdentifier);
    ConsoleWrite(uuid);
    return YES;
}

- (nonnull id<FBControlCoreLogger>)withDateFormatEnabled:(BOOL)enabled {
    return self;
}


- (nonnull id<FBControlCoreLogger>)withName:(nonnull NSString *)name {
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
