
#import <FBControlCore/FBControlCore.h>
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import <Foundation/Foundation.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "iOSReturnStatusCode.h"
#import "CodesignIdentity.h"

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

@interface FBXCTestRunStrategy (iOSDeviceManagerAdditions)

/**
 Starts testing session with the assumption that the TestRunner is properly installed
 and has an XCTestConfiguration file already


 @param iOSTarget the simulator or device to target
 @param bundleID TestRunner BundleID
 @param sessionID testing session ID
 @param attributes additional attributes used to start test runner
 @param environment additional environment used to start test runner
 @param reporter the Reporter to report test progress to.
 @param logger the logger object to log events to, may be nil.
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return testManager if the operation succeeds, otherwise nil.
 */
+ (FBTestManager *)startTestManagerForIOSTarget:(id<FBiOSTarget>)iOSTarget
                                 runnerBundleID:(NSString *)bundleID
                                      sessionID:(NSUUID *)sessionID
                                 withAttributes:(NSArray *)attributes
                                    environment:(NSDictionary *)environment
                                       reporter:(id<FBTestManagerTestReporter>)reporter
                                         logger:(id<FBControlCoreLogger>)logger
                                          error:(NSError *__autoreleasing *)error;
@end

@interface FBProcessOutputConfiguration (iOSDeviceManagerAdditions)

+ (FBProcessOutputConfiguration *)defaultForDeviceManager;

@end

@class MobileProfile;
@class Application;

@interface Device : NSObject

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) NSString *name;
@property BOOL testingComplete;

+ (instancetype)withID:(NSString *)uuid;
+ (NSArray<NSString *> *)startTestArguments;
+ (NSDictionary<NSString *, NSString *> *)startTestEnvironment;
+ (iOSReturnStatusCode)generateXCAppDataBundleAtPath:(NSString *)path
                                           overwrite:(BOOL)overwrite;

- (FBiOSDeviceOperator *)fbDeviceOperator;
- (iOSReturnStatusCode)launch;
- (iOSReturnStatusCode)kill;

- (iOSReturnStatusCode)installApp:(Application *)app shouldUpdate:(BOOL)shouldUpdate;
- (iOSReturnStatusCode)installApp:(Application *)app
                resourcesToInject:(NSArray<NSString *> *)resourcePaths
                     shouldUpdate:(BOOL)shouldUpdate;
- (iOSReturnStatusCode)installApp:(Application *)app
                    mobileProfile:(MobileProfile *)profile
                     shouldUpdate:(BOOL)shouldUpdate;
- (iOSReturnStatusCode)installApp:(Application *)app
                    mobileProfile:(MobileProfile *)profile
                resourcesToInject:(NSArray<NSString *> *)resourcePaths
                     shouldUpdate:(BOOL)shouldUpdate;
- (iOSReturnStatusCode)installApp:(Application *)app
                 codesignIdentity:(CodesignIdentity *)codesignID
                     shouldUpdate:(BOOL)shouldUpdate;
- (iOSReturnStatusCode)installApp:(Application *)app
                 codesignIdentity:(CodesignIdentity *)codesignID
                resourcesToInject:(NSArray<NSString *> *)resourcePaths
                     shouldUpdate:(BOOL)shouldUpdate;
- (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID;
- (iOSReturnStatusCode)simulateLocationWithLat:(double)lat lng:(double)lng;
- (iOSReturnStatusCode)stopSimulatingLocation;

//TODO: this should accept Env and Args
- (iOSReturnStatusCode)launchApp:(NSString *)bundleID;

- (BOOL)launchApplicationWithConfiguration:(FBApplicationLaunchConfiguration *)configuration
                                     error:(NSError **)error;
- (iOSReturnStatusCode)killApp:(NSString *)bundleID;
- (BOOL)shouldUpdateApp:(Application *)app statusCode:(iOSReturnStatusCode *)sc;
- (iOSReturnStatusCode)isInstalled:(NSString *)bundleID;
- (BOOL)isInstalled:(NSString *)bundleID withError:(NSError **)error;
- (Application *)installedApp:(NSString *)bundleID;
- (iOSReturnStatusCode)startTestWithRunnerID:(NSString *)runnerID
                                   sessionID:(NSUUID *)sessionID
                                   keepAlive:(BOOL)keepAlive;
- (iOSReturnStatusCode)uploadFile:(NSString *)filepath
                   forApplication:(NSString *)bundleID
                        overwrite:(BOOL)overwrite;
- (iOSReturnStatusCode)uploadXCAppDataBundle:(NSString *)filepath
                              forApplication:(NSString *)bundleIdentifier;
- (NSString *)containerPathForApplication:(NSString *)bundleID;
- (NSString *)installPathForApplication:(NSString *)bundleID;
- (NSString *)xctestBundlePathForTestRunnerAtPath:(NSString *)testRunnerPath;
- (BOOL)stageXctestConfigurationToTmpForBundleIdentifier:(NSString *)bundleIdentifier
                                                   error:(NSError **)error;

@end
