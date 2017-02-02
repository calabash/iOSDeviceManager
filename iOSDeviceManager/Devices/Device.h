
#import <FBControlCore/FBControlCore.h>
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import <Foundation/Foundation.h>
#import "CodesignIdentity.h"
#import <XCTestBootstrap/XCTestBootstrap.h>
#import "Application.h"
#import "iOSReturnStatusCode.h"

@class MobileProfile;

@interface Device : NSObject

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) NSString *name;
@property BOOL testingComplete;

+ (Device *)withID:(NSString *)uuid;
- (iOSReturnStatusCode)launch;
- (iOSReturnStatusCode)kill;

/**
    @warn Application should have already been staged into an alternate location when calling this,
    as this method may codesign whatever application path is passed in.
 */
- (iOSReturnStatusCode)installApp:(Application *)app shouldUpdate:(BOOL)shouldUpdate;
- (iOSReturnStatusCode)installApp:(Application *)app
                    mobileProfile:(MobileProfile *)profile
                     shouldUpdate:(BOOL)shouldUpdate;
- (iOSReturnStatusCode)installApp:(Application *)app
                 codesignIdentity:(CodesignIdentity *)codesignID
                     shouldUpdate:(BOOL)shouldUpdate;
- (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID;
- (iOSReturnStatusCode)simulateLocationWithLat:(double)lat lng:(double)lng;
- (iOSReturnStatusCode)stopSimulatingLocation;

//TODO: this should accept Env and Args
- (iOSReturnStatusCode)launchApp:(NSString *)bundleID;
- (iOSReturnStatusCode)killApp:(NSString *)bundleID;
- (BOOL)shouldUpdateApp:(Application *)app statusCode:(iOSReturnStatusCode *)sc;
- (iOSReturnStatusCode)isInstalled:(NSString *)bundleID;
- (BOOL)isInstalled:(NSString *)bundleID withError:(NSError **)error;
- (Application *)installedApp:(NSString *)bundleID;
- (iOSReturnStatusCode)startTestWithRunnerID:(NSString *)runnerID
                                   sessionID:(NSUUID *)sessionID
                                   keepAlive:(BOOL)keepAlive;
- (iOSReturnStatusCode)uploadFile:(NSString *)filepath forApplication:(NSString *)bundleID overwrite:(BOOL)overwrite;

+ (NSString *)defaultSimulatorID;
+ (NSString *)defaultPhysicalDeviceID;
+ (NSString *)defaultDeviceID;
+ (NSArray<FBDevice *> *)availableDevices;
+ (NSArray<FBSimulator *> *)availableSimulators;
+ (FBSimulator *)defaultSimulator:(NSArray<FBSimulator *>*)simulators;

@end
