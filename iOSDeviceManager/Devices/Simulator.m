
#import "Simulator.h"

#import <FBSimulatorControl/FBSimulatorControl.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import "ShellRunner.h"
#import "Codesigner.h"
#import "AppUtils.h"
#import <sqlite3.h>

@implementation Simulator
static FBSimulatorControl *_control;

+ (NSDictionary *)infoPlistForInstalledBundleID:(NSString *)bundleID
                                       deviceID:(NSString *)deviceID {
    return [self infoPlistForInstalledBundleID:bundleID
                                        device:[self simulatorWithDeviceID:deviceID]];
}

+ (NSDictionary *)infoPlistForInstalledBundleID:(NSString *)bundleID device:(FBSimulator *)device {
    FBApplicationDescriptor *installed = [device installedApplicationWithBundleID:bundleID error:nil];
    if (!installed) {
        return nil;
    }
    NSString *plistPath = [installed.path stringByAppendingPathComponent:@"Info.plist"];
    return [NSDictionary dictionaryWithContentsOfFile:plistPath];
}

+ (iOSReturnStatusCode)updateInstalledAppIfNecessary:(NSString *)bundlePath
                                              device:(FBSimulator *)device {
    NSError *e;
    FBProductBundle *newApp = [[[FBProductBundleBuilder builder]
                                withBundlePath:bundlePath]
                               buildWithError:&e];

    if (e) {
        ConsoleWriteErr(@"Unable to create product bundle for application at %@: %@", bundlePath, e);
        return iOSReturnStatusCodeGenericFailure;
    }

    FBApplicationDescriptor *installed = [device installedApplicationWithBundleID:newApp.bundleID error:&e];
    if (!installed || e) {
        ConsoleWriteErr(@"Error retrieving installed application %@: %@", newApp.bundleID, e);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSString *newPlistPath = [bundlePath stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *newPlist = [NSDictionary dictionaryWithContentsOfFile:newPlistPath];

    NSDictionary *oldPlist = [self infoPlistForInstalledBundleID:newApp.bundleID
                                                          device:device];

    if (!newPlist) {
        ConsoleWriteErr(@"Unable to locate Info.plist in app bundle: %@", bundlePath);
        return iOSReturnStatusCodeGenericFailure;
    }
    if (!oldPlist) {
        ConsoleWriteErr(@"Unable to locate Info.plist in app bundle: %@", installed.path);
        return iOSReturnStatusCodeGenericFailure;
    }

    if ([AppUtils appVersionIsDifferent:oldPlist newPlist:newPlist]) {
        ConsoleWriteErr(@"Installed version is different, attempting to update %@.", installed.bundleID);
        iOSReturnStatusCode ret = [self uninstallApp:newApp.bundleID deviceID:device.udid];
        if (ret != iOSReturnStatusCodeEverythingOkay) {
            return ret;
        }
        return [self installApp:bundlePath
                       deviceID:device.udid
                      updateApp:YES
                     codesignID:@""];
    } else {
        DDLogInfo(@"Latest version of %@ is installed, not reinstalling.", installed.bundleID);
    }

    return iOSReturnStatusCodeEverythingOkay;
}

+ (iOSReturnStatusCode)startTestOnDevice:(NSString *)deviceID
                               sessionID:(NSUUID *)sessionID
                          runnerBundleID:(NSString *)runnerBundleID
                               keepAlive:(BOOL)keepAlive {
    if (![TestParameters isSimulatorID:deviceID]) {
        ConsoleWriteErr(@"'%@' is not a valid sim ID", deviceID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    NSError *e;
    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (!simulator) { return iOSReturnStatusCodeDeviceNotFound; }

    if (simulator.state == FBSimulatorStateShutdown ) {
        [[simulator.interact bootSimulator] perform:&e];
        DDLogInfo(@"Sim is dead, booting.");
        if (e) {
            ConsoleWriteErr(@"Error booting simulator %@ for test: %@", deviceID, e);
            return iOSReturnStatusCodeInternalError;
        }
    }

    if ([self appIsInstalled:runnerBundleID deviceID:deviceID] == iOSReturnStatusCodeFalse) {
        ConsoleWriteErr(@"TestRunner %@ must be installed before you can run a test.", runnerBundleID);
        return iOSReturnStatusCodeGenericFailure;
    }

    Simulator *replog = [Simulator new];
    id<FBDeviceOperator> op = [FBSimulatorControlOperator operatorWithSimulator:simulator];
    [XCTestBootstrapFrameworkLoader loadPrivateFrameworksOrAbort];
    FBTestManager *testManager = [FBXCTestRunStrategy startTestManagerForDeviceOperator:op
                                                                         runnerBundleID:runnerBundleID
                                                                              sessionID:sessionID
                                                                         withAttributes:[FBTestRunnerConfigurationBuilder defaultBuildAttributes]
                                                                            environment:[FBTestRunnerConfigurationBuilder defaultBuildEnvironment]
                                                                               reporter:replog
                                                                                 logger:replog
                                                                                  error:&e];

    if (e) {
        ConsoleWriteErr(@"Error starting test runner: %@", e);
        return iOSReturnStatusCodeInternalError;
    } else if (keepAlive) {
        /*
         `testingComplete` will be YES when testmanagerd calls
         `testManagerMediatorDidFinishExecutingTestPlan:`
         */
        while (!replog.testingComplete){
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

            /*
             `testingHasFinished` returns YES when the bundle connection AND testmanagerd
             connection are finished with the connection (presumably at end of test or failure)
             */
            if ([testManager testingHasFinished]) {
                break;
            }
        }
        if (e) {
            ConsoleWriteErr(@"Error starting test: %@", e);
            return iOSReturnStatusCodeInternalError;
        }
    }
    return iOSReturnStatusCodeEverythingOkay;
}

+ (FBApplicationDescriptor *)app:(NSString *)appPath {
    NSError *e;
    FBApplicationDescriptor *app = [FBApplicationDescriptor applicationWithPath:appPath error:&e];
    if (!app || e) {
        ConsoleWriteErr(@"Error creating SimulatorApplication for path %@: %@", appPath, e);
        return nil;
    }
    return app;
}

+ (FBApplicationLaunchConfiguration *)testRunnerLaunchConfig:(NSString *)testRunnerPath {
    FBApplicationDescriptor *application = [self app:testRunnerPath];
    return [FBApplicationLaunchConfiguration configurationWithApplication:application
                                                                arguments:@[]
                                                              environment:@{}
                                                                  options:0];
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

+ (FBSimulator *)simulatorWithDeviceID:(NSString *)deviceID {
    FBSimulatorSet *sims = [self control].set;
    if (!sims) { return nil; }

    FBiOSTargetQuery *query = [FBiOSTargetQuery udids:@[deviceID]];
    NSArray <FBSimulator *> *results = [sims query:query];
    if (results.count == 0) {
        ConsoleWriteErr(@"No simulators found for ID %@", deviceID);
        return nil;
    }
    FBSimulator *sim = results[0];
    return sim;
}

+ (FBSimulator *)simulatorWithConfiguration:(FBSimulatorConfiguration *)configuration {
    NSError *error = nil;
    FBSimulator *simulator = [self.control.pool allocateSimulatorWithConfiguration:configuration
                                                                           options:FBSimulatorAllocationOptionsReuse
                                                                             error:&error];
    if (error) {
        ConsoleWriteErr(@"Error obtaining simulator: %@", error);
    }
    return simulator;
}

+ (FBSimulatorControl *)control {
    return _control;
}

+ (void)initialize {
    FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration
                                                      configurationWithDeviceSetPath:nil
                                                      options:FBSimulatorManagementOptionsIgnoreSpuriousKillFail];

    NSError *error;
    _control = [FBSimulatorControl withConfiguration:configuration error:&error];
    if (error) {
        ConsoleWriteErr(@"Error creating FBSimulatorControl: %@", error);
        abort();
    }
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

+ (iOSReturnStatusCode)installApp:(NSString *)pathToBundle
                         deviceID:(NSString *)deviceID
                        updateApp:(BOOL)updateApp
                       codesignID:(NSString *)codesignID {
    if (![TestParameters isSimulatorID:deviceID]) {
        ConsoleWriteErr(@"'%@' is not a valid sim ID", deviceID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    NSError *e;
    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (!simulator) { return iOSReturnStatusCodeDeviceNotFound; }

    if (simulator.state == FBSimulatorStateShutdown ||
        simulator.state == FBSimulatorStateShuttingDown) {
        ConsoleWriteErr(@"Simulator %@ is dead. Must launch sim before installing an app.", deviceID);
        return iOSReturnStatusCodeGenericFailure;
    }
    FBApplicationDescriptor *app = [self app:pathToBundle];

    Codesigner *signer = [[Codesigner alloc] initAdHocWithDeviceUDID:deviceID];

    if (![signer validateSignatureAtBundlePath:pathToBundle]) {
        NSError *signError;

        [signer signBundleAtPath:pathToBundle
                           error:&signError];

        if (signError) {
            ConsoleWriteErr(@"Error resigning sim bundle");
            ConsoleWriteErr(@"  Path to bundle: %@", pathToBundle);
            ConsoleWriteErr(@"  Device UDID: %@", deviceID);
            ConsoleWriteErr(@"  ERROR: %@", signError);
            return iOSReturnStatusCodeGenericFailure;
        }
    }

    if ([self appIsInstalled:app.bundleID deviceID:deviceID] == iOSReturnStatusCodeFalse) {
        [[simulator.interact installApplication:app] perform:&e];
    } else if (updateApp) {
        iOSReturnStatusCode ret = [self updateInstalledAppIfNecessary:pathToBundle device:simulator];
        if (ret != iOSReturnStatusCodeEverythingOkay) {
            return ret;
        }
    }

    if (e) {
        ConsoleWriteErr(@"Error installing %@ to %@: %@", app.bundleID, deviceID, e);
        return iOSReturnStatusCodeInternalError;
    } else {
        DDLogInfo(@"Installed %@ to %@", app.bundleID, deviceID);
    }
    return iOSReturnStatusCodeEverythingOkay;

}

+ (iOSReturnStatusCode)launchSimulator:(NSString *)simID {
    if (![TestParameters isSimulatorID:simID]) {
        ConsoleWriteErr(@"'%@' is not a valid sim ID", simID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    FBSimulator *simulator = [self simulatorWithDeviceID:simID];
    if (simulator == nil) {
        ConsoleWriteErr(@"");
    }
    NSError *e;
    if (simulator.state == FBSimulatorStateShutdown ||
        simulator.state == FBSimulatorStateShuttingDown) {
        DDLogInfo(@"Sim is dead, booting...");

        FBSimulatorLaunchConfiguration *launchConfig = [FBSimulatorLaunchConfiguration withOptions:
                                                        FBSimulatorLaunchOptionsConnectBridge];

        [[simulator.interact bootSimulator:launchConfig] perform:&e];
        if (e) {
            ConsoleWriteErr(@"Failed to boot sim: %@", e);
            return iOSReturnStatusCodeInternalError;
        }
    }
    return simulator != nil ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeInternalError;
}

+ (iOSReturnStatusCode)killSimulator:(NSString *)simID {
    if (![TestParameters isSimulatorID:simID]) {
        ConsoleWriteErr(@"'%@' is not a valid sim ID", simID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    FBSimulator *simulator = [self simulatorWithDeviceID:simID];
    if (simulator == nil) {
        ConsoleWriteErr(@"No such simulator exists!");
        return iOSReturnStatusCodeDeviceNotFound;
    }
    if (simulator.state == FBSimulatorStateShutdown) {
        ConsoleWriteErr(@"Simulator %@ is already shut down", simID);
        return iOSReturnStatusCodeEverythingOkay;
    } else if (simulator.state == FBSimulatorStateShuttingDown) {
        ConsoleWriteErr(@"Simulator %@ is already shutting down", simID);
        return iOSReturnStatusCodeEverythingOkay;
    }

    NSError *e;
    [[simulator.interact shutdownSimulator] perform:&e];

    if (e ) {
        ConsoleWriteErr(@"Error shutting down sim %@: %@", simID, e);
    }

    return e == nil ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeInternalError;
}

+ (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID
                           deviceID:(NSString *)deviceID {
    if (![TestParameters isSimulatorID:deviceID]) {
        ConsoleWriteErr(@"'%@' is not a valid sim ID", deviceID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (simulator == nil) {
        ConsoleWriteErr(@"No such simulator exists!");
        return iOSReturnStatusCodeDeviceNotFound;
    }
    if (simulator.state == FBSimulatorStateShutdown ||
        simulator.state == FBSimulatorStateShuttingDown) {
        ConsoleWriteErr(@"Simulator %@ is dead. Must launch before uninstalling apps.", deviceID);
        return iOSReturnStatusCodeGenericFailure;
    }

    if ([self appIsInstalled:bundleID deviceID:deviceID] == iOSReturnStatusCodeFalse) {
        ConsoleWriteErr(@"App %@ is not installed on %@", bundleID, deviceID);
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    [[simulator.interact uninstallApplicationWithBundleID:bundleID] perform:&e];
    if (e) {
        ConsoleWriteErr(@"Error uninstalling app: %@", e);
    }
    return e == nil ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeInternalError;
}

+ (iOSReturnStatusCode)appIsInstalled:(NSString *)bundleID
                             deviceID:(NSString *)deviceID {
    if (![TestParameters isSimulatorID:deviceID]) {
        ConsoleWriteErr(@"'%@' is not a valid sim ID", deviceID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (simulator == nil) {
        ConsoleWriteErr(@"No such simulator exists!");
        return iOSReturnStatusCodeDeviceNotFound;
    }

    NSError *e;
    BOOL installed = [simulator isApplicationInstalledWithBundleID:bundleID error:&e];

    if (installed) {
        [ConsoleWriter write:@"true"];
    } else {
        [ConsoleWriter write:@"false"];
    }
    
    return installed ? iOSReturnStatusCodeEverythingOkay : iOSReturnStatusCodeFalse;
}

+ (iOSReturnStatusCode)setLocation:(NSString *)deviceID
                               lat:(double)lat
                               lng:(double)lng {
    if (![TestParameters isSimulatorID:deviceID]) {
        ConsoleWriteErr(@"'%@' is not a valid sim ID", deviceID);
        return iOSReturnStatusCodeInvalidArguments;
    }

    FBSimulator *simulator = [self simulatorWithDeviceID:deviceID];
    if (simulator == nil) {
        ConsoleWriteErr(@"No such simulator exists!");
        return iOSReturnStatusCodeDeviceNotFound;
    }

    if (simulator.state == FBSimulatorStateShutdown ||
        simulator.state == FBSimulatorStateShuttingDown) {
        ConsoleWriteErr(@"Sim is dead! Must boot first");
        return iOSReturnStatusCodeGenericFailure;
    }

    NSError *e;
    FBSimulatorBridge *bridge = [FBSimulatorBridge bridgeForSimulator:simulator error:&e];
    if (e || !bridge) {
        ConsoleWriteErr(@"Unable to fetch simulator bridge: %@", e);
        return iOSReturnStatusCodeInternalError;
    }

    [bridge setLocationWithLatitude:lat longitude:lng];

    return iOSReturnStatusCodeEverythingOkay;
}

+ (iOSReturnStatusCode)uploadFile:(NSString *)filepath
                         toDevice:(NSString *)deviceID
                   forApplication:(NSString *)bundleID
                        overwrite:(BOOL)overwrite {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:filepath]) {
        ConsoleWriteErr(@"File does not exist: %@", filepath);
        return iOSReturnStatusCodeInvalidArguments;
    }
    
    NSString *containerPath = [self containerPathForApplication:bundleID device:deviceID];
    if (!containerPath) {
        ConsoleWriteErr(@"Unable to find container path for app %@ on device %@", bundleID, deviceID);
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
    
    return iOSReturnStatusCodeEverythingOkay;
}

+ (NSString *)containerPathForApplication:(NSString *)bundleID
                                   device:(NSString *)simID {
    NSFileManager *fm = [NSFileManager defaultManager];

    NSString *applicationPath = [[[[[[[[[NSHomeDirectory()
                                     stringByAppendingPathComponent:@"Library"]
                                    stringByAppendingPathComponent:@"Developer"]
                                   stringByAppendingPathComponent:@"CoreSimulator"]
                                  stringByAppendingPathComponent:@"Devices"]
                                 stringByAppendingPathComponent:simID]
                                stringByAppendingPathComponent:@"data"]
                               stringByAppendingPathComponent:@"Containers"]
                              stringByAppendingPathComponent:@"Data"]
                             stringByAppendingPathComponent:@"Application"];
    
    NSArray *bundleFolders = [fm contentsOfDirectoryAtPath:applicationPath error:nil];
    
        NSString *bundleFolderPath = [applicationPath stringByAppendingPathComponent:bundleFolder];
    for (id bundleFolder in bundleFolders) {
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

+ (NSString *)containerPathForApplication:(NSString *)bundleID
                             fromSQLiteDB:(NSString *)dbPath {
    sqlite3 *db;
    if (sqlite3_open(dbPath.UTF8String, &db) != SQLITE_OK) {
        ConsoleWriteErr(@"Unable to open %@", [dbPath lastPathComponent]);
        return nil;
    }
    
    NSError *e;
    NSString *query = [NSString stringWithFormat:
                       @"SELECT value FROM kvs_debug "
                       "WHERE application_identifier = '%@' "
                       "AND key = 'XBApplicationSnapshotManifest'",
                       bundleID];
    sqlite3_stmt *statement;
    int result = sqlite3_prepare_v2(db, query.UTF8String, -1, &statement, nil);
    if (result == SQLITE_OK) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            const void *plistBytes = sqlite3_column_blob(statement, 0);
            int numBytes = sqlite3_column_bytes(statement, 0);
            //TODO: `plist` is actually an NSKeyedArchiver archive
            NSData *plistData = [NSData dataWithBytes:plistBytes length:numBytes];
            NSData *plist = [NSPropertyListSerialization propertyListWithData:plistData
                                                                            options:0
                                                                             format:NULL
                                                                              error:&e];
            if (e) {
                ConsoleWriteErr(@"Error serializing data into plist dictionary: %@", e);
                return nil;
            }
            
            NSDictionary *plistPlist = [NSJSONSerialization JSONObjectWithData:plist options:NSJSONReadingAllowFragments error:&e];
            ConsoleWrite(@"%@", plistPlist);
            sqlite3_finalize(statement);
            if (e) {
                ConsoleWriteErr(@"Error serializing data into plist dictionary: %@", e);
                return nil;
            }
        } else {
            ConsoleWriteErr(@"Unable to find installation plist inside of %@",
                            dbPath.lastPathComponent);
            return nil;
        }
    } else {
        ConsoleWriteErr(@"Error preparing sql query statement %@. Error code %@",
                        query,
                        @(result));
        return nil;
    }
    
    sqlite3_close(db);
    return @"";
}

@end
