
#import "Simulator.h"
#import "AppUtils.h"
#import "Codesigner.h"
#import "ConsoleWriter.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "XCTestConfigurationPlist.h"
#import "XCAppDataBundle.h"
#import <FBControlCore/FBControlCore.h>

@interface SimDevice : NSObject

- (BOOL)bootWithOptions:(NSDictionary *)options error:(NSError *__autoreleasing *)error;
- (NSDictionary *)installedAppsWithError:(NSError **)error;

@end

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
    
    FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration configurationWithDeviceSetPath:nil logger:nil reporter:nil];
//    FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration
//                                                      configurationWithDeviceSetPath:nil
//                                                      options:FBSimulatorManagementOptionsIgnoreSpuriousKillFail];
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

    FBiOSTargetQuery *query = [FBiOSTargetQuery udids:@[uuid]];
    NSArray <FBSimulator *> *results = [sims query:query];
    if (results.count == 0) {
        ConsoleWriteErr(@"No simulators found for ID %@", uuid);
        return nil;
    }

    simulator.fbSimulator = results[0];

    return simulator;
}

+ (FBSimulatorLifecycleCommands *)lifecycleCommandsWithFBSimulator:(FBSimulator *)simulator {
    
    
    FBSimulatorConnection *connection = [[FBSimulatorConnection alloc] initWithSimulator:simulator framebuffer:nil hid:nil];
   
    [[connection terminate] timeout:5 waitingFor:@"The Simulator Connection to teardown"];
    
    return [FBSimulatorLifecycleCommands commandsWithTarget:simulator];
}

//+ (FBSimulatorLifecycleCommands *)lifecycleCommandsWithFBSimulator:(FBSimulator *)simulator {
//    FBSimulatorEventRelay *relay = [simulator eventSink];
//    if (relay.connection) {
//        [relay.connection terminateWithTimeout:5];
//    }
//
//    return [FBSimulatorLifecycleCommands commandsWithSimulator:simulator];
//}

+ (FBSimulatorApplicationCommands *)applicationCommandsWithFBSimulator:(FBSimulator *)simulator {
    return [FBSimulatorApplicationCommands commandsWithTarget:simulator];
}

+ (NSURL *)simulatorAppURL {
    NSString *path = [[FBBundleDescriptor xcodeSimulator] path];

    return [NSURL fileURLWithPath:path];
}

+ (BOOL)waitForSimulatorAppServices:(FBSimulator *)fbSimulator {
    NSArray<NSString *> *requiredServiceNames = [Simulator requiredSimulatorAppProcesses];
    __block NSDictionary<id, NSString *> *processIdentifiers = @{};
    BOOL success = NO;

    return [NSRunLoop.currentRunLoop spinRunLoopWithTimeout:120 untilTrue:^BOOL{
        FBFuture<NSDictionary<NSString *,id> *> *future_list = [fbSimulator listServices];
        NSDictionary<NSString *,id> *services = future_list.result;
        // No services running yet.
        if (!services) { return NO; }
        
        NSArray *keys = [services objectsForKeys:requiredServiceNames
                                  notFoundMarker:[NSNull null]];
        processIdentifiers = [NSDictionary dictionaryWithObjects:requiredServiceNames
                                                         forKeys:keys];
        
        // At least on process has not launched yet.
        if (processIdentifiers[NSNull.null]) { return NO; }
        
        // No null values in the dictionary means all processes have started.
        return YES;
    }];

    return success;
}

+ (NSArray<NSString *> *)requiredSimulatorAppProcesses {
    return @[@"com.apple.backboardd",
             @"com.apple.mobile.installd",
             @"com.apple.SpringBoard"];
}

+ (iOSReturnStatusCode)launchSimulator:(Simulator *)simulator {
    NSError *error = nil;
    if ([simulator waitForBootableState:&error]) {

        error = nil;
        BOOL success = [simulator launchSimulatorApp:&error];
        if (success) {
            return iOSReturnStatusCodeEverythingOkay;
        } else {
            ConsoleWriteErr(@"Could not launch simulator");
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
    FBiOSTargetQuery *query = [FBiOSTargetQuery allTargets];
    NSArray <FBSimulator *> *results = [simulators query:query];
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
//    FBFuture<NSArray<FBSimulator *> *> *simulatorFutures = [FBFuture futureWithFutures:@[
//      [self assertObtainsSimulatorWithConfiguration:[FBSimulatorConfiguration withDeviceModel:SimulatorControlTestsDefaultiPhoneModel]],
//      [self assertObtainsSimulatorWithConfiguration:[FBSimulatorConfiguration withDeviceModel:SimulatorControlTestsDefaultiPhoneModel]],
//      [self assertObtainsSimulatorWithConfiguration:[FBSimulatorConfiguration withDeviceModel:SimulatorControlTestsDefaultiPadModel]],
//    ]];
//    NSError *error = nil;
//    NSArray<FBSimulator *> *simulators = [simulatorFutures await:&error];
//    XCTAssertNil(error);
//    XCTAssertTrue(simulators);
//
//    FBSimulator *simulator1 = simulators[0];
    
    
    
    NSError *error = nil;
    //[[[simulator.fbSimulator.set eraseSimulator:simulator.fbSimulator] mapReplace:NSNull.null] await:&error];
    
    

//    BOOL success = [[simulator.fbSimulator shutdown] await:&error] != nil;
    FBFuture *shutdownFuture = [FBFuture futureWithFutures:@[
      [simulator.fbSimulator shutdown],
    ]];
    BOOL success = [shutdownFuture await:&error] != nil;
    
    if (!success){
        ConsoleWriteErr(@"Error: Could not shutdown simulator: %@", simulator);
        return iOSReturnStatusCodeInternalError;
    }
    
    [[simulator.fbSimulator erase] await:&error];
    
    if (error){
        ConsoleWriteErr(@"Error: Could not shutdown simulator: %@", simulator);
        return iOSReturnStatusCodeInternalError;
    }
    
    return iOSReturnStatusCodeEverythingOkay;
//    [Simulator killSimulatorApp];
//    if (![simulator waitForSimulatorState:FBiOSTargetStateShutdown timeout:30]) {
//        ConsoleWriteErr(@"Error: Could not shutdown simulator: %@", simulator);
//        return iOSReturnStatusCodeInternalError;
//    }
//
//    FBFuture<NSNull *> *future = [simulator.fbSimulator erase];
//
//
//    NSError *error = nil;
////    if ([[simulator.fbSimulator erase] await:&error] == nil) {
//    if (!future.result) {
//        ConsoleWriteErr(@"Error: %@", [error localizedDescription]);
//        return iOSReturnStatusCodeInternalError;
//    }
//
//    return iOSReturnStatusCodeEverythingOkay;
}

- (FBiOSTargetState)state {
    return self.fbSimulator.state;
}

- (NSString *)stateString {
    return self.fbSimulator.stateString;
}

- (BOOL)waitForSimulatorState:(FBiOSTargetState)state
                      timeout:(NSTimeInterval)timeout {
    
    FBFuture<NSNull *> *future = [[self.fbSimulator resolveState:state]
            timeout:timeout waitingFor:@"Simulator to resolve state %@", state];
    
    if (future.result) {
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
                                 timeout:30]) {
            ConsoleWriteErr(@"Could not boot simulator");
            return NO;
        } else {
            return YES;
        }
    } else {

        NSDictionary *options = @{};
        SimDevice *simDevice = [self.fbSimulator device];
        if (![simDevice bootWithOptions:options
                                  error:&error]) {
            ConsoleWriteErr(@"Could not boot simulator");
            if (error) {
                ConsoleWriteErr(@"%@", [error localizedDescription]);
            }
            return NO;
        } else {
            if (![self waitForSimulatorState:FBiOSTargetStateBooted
                                     timeout:30]) {
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

    NSDictionary *configuration =
    @{
      NSWorkspaceLaunchConfigurationArguments : arguments,
      NSWorkspaceLaunchConfigurationEnvironment : @{}
      };

    NSWorkspaceLaunchOptions options;
    // NSWorkspaceLaunchAndHide - use this if launching simulator steals focus
    // NSWorkspaceLaunchNewInstance - create a new Simulator.app window,
    //                                even if one is already open.
    options = NSWorkspaceLaunchDefault | NSWorkspaceLaunchWithoutActivation;

    NSURL *url = [Simulator simulatorAppURL];
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSRunningApplication *application;
    application = [workspace launchApplicationAtURL:url
                                            options:options
                                      configuration:configuration
                                              error:error];

    if (!application) {
        ConsoleWriteErr(@"Could not launch Simulator.app for %@", self.fbSimulator);
        return NO;
    }

    pid_t pid = [application processIdentifier];
    FBProcessFetcher *fetcher = [FBProcessFetcher new];
    FBProcessInfo *info = [fetcher processInfoFor:pid];

    if (![info.arguments containsObject:self.uuid]) {
        ConsoleWrite(@"Running simulator udid does not match %@", self.uuid);
        ConsoleWrite(@"Restarting the simulator");
        [Simulator killSimulatorApp];
        return [self launchSimulatorApp:error];
    }

    if(![Simulator waitForSimulatorAppServices:self.fbSimulator]) {
        ConsoleWriteErr(@"Timed out waiting for all simulator services to start");
    }

    return YES;
}

- (BOOL)shutdown {
    NSError *error = nil;
    if (self.state == FBiOSTargetStateShutdown) { return YES; }

    FBSimulatorShutdownStrategy *strategy;
    strategy = [FBSimulatorShutdownStrategy strategyWithSimulator:self.fbSimulator];

    if (self.state != FBiOSTargetStateShuttingDown ||
        self.state == FBiOSTargetStateShutdown) {
        
        if (![[strategy shutdown] await:&error]) {
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
                success = NO;
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

            if ([[self.fbSimulator isApplicationInstalledWithBundleID:bundleID] await:&error]) {
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
    FBSimulatorBridge *bridge = [[FBSimulatorBridge bridgeForSimulator:self.fbSimulator] await:&error];
    if (!bridge) {
        ConsoleWriteErr(@"Unable to fetch simulator bridge: %@");
        if (error) {
            ConsoleWriteErr(@"%@", [error localizedDescription]);
        }
        return iOSReturnStatusCodeInternalError;
    }

    [bridge setLocationWithLatitude:lat longitude:lng];

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
        ConsoleWriteErr(@"Could not launch the Simulator.app");
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
    [[self.fbSimulator launchApplication:configuration] await:error];
    if (*error) {
        return NO;
    }
    else{
        return YES;
    }
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

    if ([[self.fbSimulator isApplicationInstalledWithBundleID:bundleID] await:error]) {
        return YES;
    }

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

@end
