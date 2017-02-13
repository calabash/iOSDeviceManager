
#import <FBControlCore/FBControlCore.h>
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import <Foundation/Foundation.h>
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "Application.h"
#import "iOSReturnStatusCode.h"
#import "CodesignIdentity.h"


@interface FBiOSDeviceOperator (iOSDeviceManagerAdditions)

- (id<DVTApplication>)installedApplicationWithBundleIdentifier:(NSString *)bundleID;
- (BOOL)isApplicationInstalledWithBundleID:(NSString *)bundleID error:(NSError **)error;
- (BOOL)installApplicationWithPath:(NSString *)path error:(NSError **)error;
- (BOOL)launchApplication:(FBApplicationLaunchConfiguration *)configuration error:(NSError **)error;

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

@interface Device : NSObject

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray <CodesignIdentity *> *identities;
@property BOOL testingComplete;

+ (Device *)withID:(NSString *)uuid;
- (iOSReturnStatusCode)launch;
- (iOSReturnStatusCode)kill;
- (iOSReturnStatusCode)installApp:(Application *)app shouldUpdate:(BOOL)shouldUpdate;
- (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID;
- (iOSReturnStatusCode)simulateLocationWithLat:(double)lat lng:(double)lng;
- (iOSReturnStatusCode)stopSimulatingLocation;
- (iOSReturnStatusCode)launchApp:(NSString *)bundleID;
- (iOSReturnStatusCode)killApp:(NSString *)bundleID;
- (iOSReturnStatusCode)isInstalled:(NSString *)bundleID;
- (Application *)installedApp:(NSString *)bundleID;
- (iOSReturnStatusCode)startTestWithRunnerID:(NSString *)runnerID sessionID:(NSUUID *)sessionID keepAlive:(BOOL)keepAlive;
- (iOSReturnStatusCode)uploadFile:(NSString *)filepath forApplication:(NSString *)bundleID overwrite:(BOOL)overwrite;

@end
