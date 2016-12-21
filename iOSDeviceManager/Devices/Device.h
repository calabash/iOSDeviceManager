
#import "TestParameters.h"
#import <FBControlCore/FBControlCore.h>
#import "iOSDeviceManagementCommand.h"
#import <Foundation/Foundation.h>
#import "CodesignIdentity.h"
#import <XCTestBootstrap/XCTestBootstrap.h>

@interface Device : NSObject

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray <CodesignIdentity *> *identities;
@property (nonatomic, strong) NSMutableArray <FBApplicationDescriptor *> *apps;

@property BOOL testingComplete;

+ (Device *)withID:(NSString *)uuid;
- (iOSReturnStatusCode)launch;
- (iOSReturnStatusCode)kill;
- (iOSReturnStatusCode)installApp:(FBApplicationDescriptor *)app updateApp:(BOOL)updateApp;
- (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID;
- (iOSReturnStatusCode)simulateLocationWithLat:(double)lat lng:(double)lng;
- (iOSReturnStatusCode)stopSimulatingLocation;
- (iOSReturnStatusCode)launchApp:(NSString *)bundleID;
- (iOSReturnStatusCode)killApp:(NSString *)bundleID;
- (BOOL)isInstalled:(NSString *)bundleID;
- (FBApplicationDescriptor *)installedApp:(NSString *)bundleID;
- (iOSReturnStatusCode)startTestWithRunnerID:(NSString *)runnerID sessionID:(NSUUID *)sessionID keepAlive:(BOOL)keepAlive;
- (iOSReturnStatusCode)uploadFile:(NSString *)filepath forApplication:(NSString *)bundleID overwrite:(BOOL)overwrite;

/**
 Defined as first available launched simulator if any, 
 else first attached device,
 else nil.
 */
+ (NSString *)defaultDeviceID;

@end
