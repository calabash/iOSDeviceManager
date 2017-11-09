
#import "PhysicalDevice.h"
#import "ShellRunner.h"
#import "Simulator.h"
#import "AppUtils.h"
#import "ConsoleWriter.h"
#import "DeviceUtils.h"
#import "XCAppDataBundle.h"
#import "FileUtils.h"


#define MUST_OVERRIDE @throw [NSException exceptionWithName:@"ProgrammerErrorException" reason:@"Method should be overridden by a subclass" userInfo:@{@"method" : NSStringFromSelector(_cmd)}]

@implementation FBProcessOutputConfiguration (iOSDeviceManagerAdditions)

+ (FBProcessOutputConfiguration *)defaultForDeviceManager {
    return [FBProcessOutputConfiguration outputToDevNull];
}

@end

@implementation Device

- (id)init {
    if (self = [super init]) {
        _testingComplete = NO;
    }
    return self;
}

+ (instancetype)withID:(NSString *)uuid {
    if ([DeviceUtils isSimulatorID:uuid]) { return [Simulator withID:uuid]; }
    if ([DeviceUtils isDeviceID:uuid]) { return [PhysicalDevice withID:uuid]; }
    ConsoleWriteErr(@"Specified device ID does not match simulator or device");
    return nil;
}

+ (void)initialize {
    const char *FBLog = [ShellRunner verbose] ? "YES" : "NO";
    setenv("FBCONTROLCORE_LOGGING", FBLog, 1);
    setenv("FBCONTROLCORE_DEBUG_LOGGING", FBLog, 1);
}

+ (iOSReturnStatusCode)generateXCAppDataBundleAtPath:(NSString *)path
                                           overwrite:(BOOL)overwrite {
    NSString *expanded = [FileUtils expandPath:path];
    NSString *basePath = [expanded stringByDeletingLastPathComponent];
    NSString *name = [expanded lastPathComponent];

    if ([XCAppDataBundle generateBundleSkeleton:basePath
                                           name:name
                                      overwrite:overwrite]) {
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        return iOSReturnStatusCodeGenericFailure;
    }
}

#pragma mark - Instance Methods

- (BOOL)shouldUpdateApp:(Application *)app statusCode:(iOSReturnStatusCode *)sc {
    NSError *isInstalledError;
    if ([self isInstalled:app.bundleID withError:&isInstalledError]) {
        Application *installedApp = [self installedApp:app.bundleID];
        NSDictionary *oldPlist = installedApp.infoPlist;
        NSDictionary *newPlist = app.infoPlist;

        if (oldPlist.count == 0) {
            ConsoleWriteErr(@"Error fetching/parsing plist from installed application $@", installedApp.bundleID);
            *sc = iOSReturnStatusCodeGenericFailure;
            return NO;
        }

        if (newPlist.count == 0) {
            ConsoleWriteErr(@"Unable to find Info.plist for bundle path %@", app.path);
            *sc = iOSReturnStatusCodeGenericFailure;
            return NO;
        }

        if ([AppUtils appVersionIsDifferent:oldPlist newPlist:newPlist]) {
            ConsoleWrite(@"Installed version is different, attempting to update %@.", app.bundleID);
            return YES;
        } else {
            ConsoleWrite(@"Latest version of %@ is installed, not reinstalling.", app.bundleID);
            return NO;
        }
    }

    //If it's not installed, it should be 'updated'
    return YES;
}

- (BOOL)isInstalled:(NSString *)bundleID withError:(NSError **)error {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)installApp:(Application *)app shouldUpdate:(BOOL)shouldUpdate {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)installApp:(Application *)app
                resourcesToInject:(NSArray<NSString *> *)resourcePaths
                     shouldUpdate:(BOOL)shouldUpdate {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)installApp:(Application *)app
                    mobileProfile:(MobileProfile *)profile
                     shouldUpdate:(BOOL)shouldUpdate {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)installApp:(Application *)app
                    mobileProfile:(MobileProfile *)profile
                resourcesToInject:(NSArray<NSString *> *)resourcePaths
                     shouldUpdate:(BOOL)shouldUpdate {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)installApp:(Application *)app
                 codesignIdentity:(CodesignIdentity *)codesignID
                     shouldUpdate:(BOOL)shouldUpdate {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)installApp:(Application *)app
                 codesignIdentity:(CodesignIdentity *)codesignID
                resourcesToInject:(NSArray<NSString *> *)resourcePaths
                     shouldUpdate:(BOOL)shouldUpdate {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)simulateLocationWithLat:(double)lat lng:(double)lng {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)stopSimulatingLocation {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)launchApp:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (BOOL)launchApplicationWithConfiguration:(FBApplicationLaunchConfiguration *)configuration
                                     error:(NSError **)error {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)killApp:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)isInstalled:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (Application *)installedApp:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)uploadFile:(NSString *)filepath
                   forApplication:(NSString *)bundleID
                        overwrite:(BOOL)overwrite {
    MUST_OVERRIDE;
}

- (iOSReturnStatusCode)uploadXCAppDataBundle:(NSString *)filepath
                              forApplication:(NSString *)bundleIdentifier {
    MUST_OVERRIDE;
}

- (NSString *)containerPathForApplication:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (NSString *)installPathForApplication:(NSString *)bundleID {
    MUST_OVERRIDE;
}

- (NSString *)xctestBundlePathForTestRunnerAtPath:(NSString *)testRunnerPath {
    if (![testRunnerPath hasSuffix:@"-Runner.app"]) {
        NSString *name = [testRunnerPath lastPathComponent];
        ConsoleWriteErr(@"Expected test runner '%@' to end with -Runner.app", name);
        ConsoleWriteErr(@"Cannot detect xctestBundlePath from test runner path:");
        ConsoleWriteErr(@"  %@", testRunnerPath);
        return nil;
    }

    NSArray *tokens = [[testRunnerPath lastPathComponent]
                       componentsSeparatedByString:@"-Runner.app"];
    if ([tokens count] != 2) {
        NSString *name = [testRunnerPath lastPathComponent];
        ConsoleWriteErr(@"Expected test runner '%@' to end with -Runner.app", name);
        ConsoleWriteErr(@"Cannot detect xctestBundlePath from test runner path:");
        ConsoleWriteErr(@"  %@", testRunnerPath);
        return nil;
    }

    NSString *bundleName = [NSString stringWithFormat:@"%@.xctest", tokens[0]];
    NSString *bundlePath = [@"PlugIns" stringByAppendingPathComponent:bundleName];
    return [testRunnerPath stringByAppendingPathComponent:bundlePath];
}

- (BOOL)stageXctestConfigurationToTmpForBundleIdentifier:(NSString *)bundleIdentifier
                                                   error:(NSError **)error {
    MUST_OVERRIDE;
}

@end
