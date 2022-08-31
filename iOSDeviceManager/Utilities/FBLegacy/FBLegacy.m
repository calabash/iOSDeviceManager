//
//  FBLegacy.m
//  iOSDeviceManager
//
//  Created by Алан Максвелл on 07.07.2021.
//  Copyright © 2021 Microsoft. All rights reserved.
//

#import "FBLegacy.h"
#import <objc/runtime.h>
#import <stdatomic.h>

@implementation FBLegacy

////
//legacy frameworks that are required for .xcappdata container download and upload
+ (FBWeakFramework *)DevToolsFoundation
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../PlugIns/Xcode3Core.ideplugin/Contents/Frameworks/DevToolsFoundation.framework" requiredClassNames:@[]];
}

+ (FBWeakFramework *)DevToolsSupport
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../PlugIns/Xcode3Core.ideplugin/Contents/Frameworks/DevToolsSupport.framework" requiredClassNames:@[]];
}

+ (FBWeakFramework *)DevToolsCore
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../PlugIns/Xcode3Core.ideplugin/Contents/Frameworks/DevToolsCore.framework" requiredClassNames:@[]];
}

+ (FBWeakFramework *)AssetCatalogFoundation
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../Frameworks/AssetCatalogFoundation.framework" requiredClassNames:@[]];
}

+ (FBWeakFramework *)IBAutolayoutFoundation
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../Frameworks/IBAutolayoutFoundation.framework" requiredClassNames:@[]];
}

+ (FBWeakFramework *)IDEKit
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../Frameworks/IDEKit.framework" requiredClassNames:@[]];
}

+ (FBWeakFramework *)DebugHierarchyFoundation
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../SharedFrameworks/DebugHierarchyFoundation.framework" requiredClassNames:@[]];
}

+ (FBWeakFramework *)DebugHierarchyKit
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../SharedFrameworks/DebugHierarchyKit.framework" requiredClassNames:@[]];
}

//functons that are required for .xcappdata container download and upload
+ (void)loadPrivateFrameworksOrAbort:(NSArray<FBWeakFramework *> *)frameworks
{
  id<FBControlCoreLogger> logger = FBControlCoreGlobalConfiguration.defaultLogger;
  NSError *error = nil;
    for(FBWeakFramework *framework in frameworks) {
        if(![framework loadWithLogger:logger error:&error]) {
            NSString *message = [NSString stringWithFormat:@"Failed to load private frameworks with error %@", error];

            // Log the message.
            [logger.error log:message];
            // Assertions give a better message in the crash report.
            NSAssert(NO, message);
            // However if assertions are compiled out, then we still need to abort.
            abort();
        }
    }
}

/**
Load all frameworks and libraries that are required by DVT
DVT contains an old set of functions
*/
+(void)loadDVTFrameworks{
    NSError *err;
    
    for (FBDependentDylib *dylib in [FBDependentDylib SwiftDylibs]) {
        if (![dylib loadWithLogger:FBControlCoreGlobalConfiguration.defaultLogger error:&err]) {
            ConsoleWriteErr(@"Failed to initialize SwiftDylibs");
        }
    }
    
    NSMutableArray<FBWeakFramework *> *frameworks = [[NSMutableArray alloc] init];
    
    FBWeakFramework *mobileDeviceFramework = [FBWeakFramework frameworkWithPath:@"/System/Library/PrivateFrameworks/MobileDevice.framework" requiredClassNames:@[] rootPermitted:NO];
    
    [frameworks addObject:mobileDeviceFramework];
    
    FBWeakFramework *dtxConnectionFramework = [FBWeakFramework xcodeFrameworkWithRelativePath:@"../SharedFrameworks/DTXConnectionServices.framework" requiredClassNames:@[@"DTXConnection", @"DTXRemoteInvocationReceipt"]];
    [frameworks addObject:dtxConnectionFramework];
    
    FBWeakFramework *ideFoundationFramework = [FBWeakFramework xcodeFrameworkWithRelativePath:@"../Frameworks/IDEFoundation.framework" requiredClassNames:@[@"IDEFoundationTestInitializer"]];
    
    [frameworks addObject:ideFoundationFramework];
    
    ///IDEiOSSupportCore loading doesn't work without these three frameworks loading
    [frameworks addObject:[self DevToolsFoundation]];
    [frameworks addObject:[self DevToolsSupport]];
    [frameworks addObject:[self DevToolsCore]];
    
    
    FBWeakFramework *ideiOSSupportCorePlugin = [FBWeakFramework xcodeFrameworkWithRelativePath:@"../PlugIns/IDEiOSSupportCore.ideplugin" requiredClassNames:@[@"DVTiPhoneSimulator"]];
    
    [frameworks addObject:ideiOSSupportCorePlugin];
    ///
    
    ///IBAutolayoutFoundation loading doesn't work without AssetCatalogFoundation framework loading
    [frameworks addObject:[self AssetCatalogFoundation]];
    [frameworks addObject:[self IBAutolayoutFoundation]];
    ///

    [frameworks addObject:[self IDEKit]];
    
    [frameworks addObject:[self DebugHierarchyFoundation]];
    [frameworks addObject:[self DebugHierarchyKit]];
    
    [self loadPrivateFrameworksOrAbort:frameworks];
    
    
    if (![objc_lookUpClass("IDEFoundationTestInitializer") initializeTestabilityWithUI:NO error:&err]) {
        ConsoleWriteErr(@"Failed to initialize testability");
    }
    
    if (![objc_lookUpClass("DVTPlatform") loadAllPlatformsReturningError:&err]) {
        ConsoleWriteErr(@"Failed to load all platforms");
    }
    
    if (![objc_lookUpClass("DVTDeviceType") deviceTypeWithIdentifier:@"Xcode.DeviceType.iPhone"]) {
        ConsoleWriteErr(@"Device Type 'Xcode.DeviceType.iPhone' hasn't been initialized yet");
    }
    
    if (!objc_lookUpClass("DVTDeviceType")) {
        ConsoleWriteErr(@"Device Type 'Xcode.DeviceType.iPhone' hasn't been initialized yet");
    }
}

+ (NSDictionary<NSString *, DVTiOSDevice *> *)keyDVTDevicesByUDID:(NSArray<DVTiOSDevice *> *)devices
{
  NSMutableDictionary<NSString *, DVTiOSDevice *> *dictionary = [NSMutableDictionary dictionary];
  for (DVTiOSDevice *device in devices) {
    dictionary[device.identifier] = device;
  }
  return [dictionary copy];
}

static DVTiOSDevice * _dvtDevice;
+ (DVTiOSDevice*)dvtDevice { return _dvtDevice; }
//@dynamic dvtDevice;

+ (void)fetchApplications:(FBDevice *)fbDevice
{
    
    [FBLegacy loadDVTFrameworks];
    
    // It seems that searching for a device that does not exist will cause all available devices/simulators etc. to be cached.
    // There's probably a better way of fetching all the available devices, but this appears to work well enough.
    // This means that all the cached available devices can then be found.
    
    DVTDeviceManager *deviceManager = [objc_lookUpClass("DVTDeviceManager") defaultDeviceManager];
    ConsoleWriteErr(@"Quering device manager for %f seconds to cache devices");
    [deviceManager searchForDevicesWithType:nil options:@{@"id" : @"I_DONT_EXIST_AT_ALL"} timeout:2 error:nil];
    ConsoleWriteErr(@"Finished querying devices to cache them");
    
    NSDictionary<NSString *, DVTiOSDevice *> *dvtDevices = [self keyDVTDevicesByUDID:[objc_lookUpClass("DVTiOSDevice") alliOSDevices]];
    
    _dvtDevice = dvtDevices[fbDevice.udid];
    
    NSError *e;
    
    if (!self.dvtDevice.applications) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void){
            DVTFuture *future = self.dvtDevice.token.fetchApplications;
            [future waitUntilFinished];
        });
    }
    //added by myself - without this line the dvtDevice variable contains no applications
    [[fbDevice installedApplications] await:&e];//NSArray<FBInstalledApplication *> * apps =
    while (!self.dvtDevice.applications){
        usleep(500);
        ConsoleWriteErr(@"Wait for the applications");
    }
}

+ (BOOL)uploadApplicationDataAtPath:(NSString *)path bundleID:(NSString *)bundleID error:(NSError **)error
{
    if(FBLegacy.dvtDevice == nil){
        return NO;
    }
    __block NSError *innerError = nil;
    __block volatile atomic_bool didFinish = false;
    __block id returnObject;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      returnObject = @([FBLegacy.dvtDevice uploadApplicationDataWithPath:path forInstalledApplicationWithBundleIdentifier:bundleID error:&innerError]);
      atomic_fetch_or(&didFinish, true);
    });
    while (!didFinish) {
      [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    *error = innerError;
    
    return [returnObject boolValue];
}


+ (BOOL)downloadApplicationDataToPath:(NSString *)path bundleID:(NSString *)bundleID error:(NSError **)error{
    return [_dvtDevice downloadApplicationDataToPath:path
         forInstalledApplicationWithBundleIdentifier:bundleID
                                               error:error];
}

////

////
//functional for provisioning profile installation

_Nullable CFArrayRef (*_Nonnull FBAMDCreateDeviceList)(void);
int (*FBAMDeviceConnect)(CFTypeRef device);
int (*FBAMDeviceDisconnect)(CFTypeRef device);
int (*FBAMDeviceIsPaired)(CFTypeRef device);
int (*FBAMDeviceValidatePairing)(CFTypeRef device);
int (*FBAMDeviceStartSession)(CFTypeRef device);
int (*FBAMDeviceStopSession)(CFTypeRef device);
int (*FBAMDServiceConnectionGetSocket)(CFTypeRef connection);
int (*FBAMDServiceConnectionInvalidate)(CFTypeRef connection);
int (*FBAMDeviceSecureStartService)(CFTypeRef device, CFStringRef service_name, _Nullable CFDictionaryRef userinfo, void *handle);
_Nullable CFStringRef (*_Nonnull FBAMDeviceGetName)(CFTypeRef device);
_Nullable CFStringRef (*_Nonnull FBAMDeviceCopyValue)(CFTypeRef device, _Nullable CFStringRef domain, CFStringRef name);
int (*FBAMDeviceSecureTransferPath)(int arg0, CFTypeRef arg1, CFURLRef arg2, CFDictionaryRef arg3, void *_Nullable arg4, int arg5);
int (*FBAMDeviceSecureInstallApplication)(int arg0, CFTypeRef arg1, CFURLRef arg2, CFDictionaryRef arg3,  void *_Nullable arg4, int arg5);
int (*FBAMDeviceSecureUninstallApplication)(int arg0, CFTypeRef arg1, CFStringRef arg2, int arg3, void *_Nullable arg4, int arg5);
int (*FBAMDeviceLookupApplications)(CFTypeRef arg0, CFDictionaryRef arg1, CFDictionaryRef *arg2);
int (*FBAMDeviceInstallProvisioningProfile)(CFTypeRef device, CFTypeRef profile, void *_Nullable handle);
_Nullable CFTypeRef (*_Nonnull FBMISProfileCreateWithFile)(int arg0, CFStringRef profilePath);
MISProfileRef (*FBMISProfileCreateWithData)(CFDataRef data);
void (*FBAMDSetLogLevel)(int32_t level);

+ (void)loadFBAMDeviceSymbols
{
  void *handle = dlopen("/System/Library/PrivateFrameworks/MobileDevice.framework/Versions/A/MobileDevice", RTLD_LAZY);
  NSCAssert(handle, @"MobileDevice could not be opened");
  FBAMDSetLogLevel = (void(*)(int32_t))FBGetSymbolFromHandle(handle, "AMDSetLogLevel");
  FBAMDeviceConnect = (int(*)(CFTypeRef device))FBGetSymbolFromHandle(handle, "AMDeviceConnect");
  FBAMDeviceDisconnect = (int(*)(CFTypeRef device))FBGetSymbolFromHandle(handle, "AMDeviceDisconnect");
  FBAMDeviceIsPaired = (int(*)(CFTypeRef device))FBGetSymbolFromHandle(handle, "AMDeviceIsPaired");
  FBAMDeviceValidatePairing = (int(*)(CFTypeRef device))FBGetSymbolFromHandle(handle, "AMDeviceValidatePairing");
  FBAMDeviceStartSession = (int(*)(CFTypeRef device))FBGetSymbolFromHandle(handle, "AMDeviceStartSession");
  FBAMDeviceStopSession =  (int(*)(CFTypeRef device))FBGetSymbolFromHandle(handle, "AMDeviceStopSession");
  FBAMDServiceConnectionGetSocket = (int(*)(CFTypeRef))FBGetSymbolFromHandle(handle, "AMDServiceConnectionGetSocket");
  FBAMDServiceConnectionInvalidate = (int(*)(CFTypeRef))FBGetSymbolFromHandle(handle, "AMDServiceConnectionInvalidate");
  FBAMDeviceSecureStartService = (int(*)(CFTypeRef, CFStringRef, CFDictionaryRef, void *))FBGetSymbolFromHandle(handle, "AMDeviceSecureStartService");
  FBAMDCreateDeviceList = (CFArrayRef(*)(void))FBGetSymbolFromHandle(handle, "AMDCreateDeviceList");
  FBAMDeviceGetName = (CFStringRef(*)(CFTypeRef))FBGetSymbolFromHandle(handle, "AMDeviceGetName");
  FBAMDeviceCopyValue = (CFStringRef(*)(CFTypeRef, CFStringRef, CFStringRef))FBGetSymbolFromHandle(handle, "AMDeviceCopyValue");
  FBAMDeviceSecureTransferPath = (int(*)(int, CFTypeRef, CFURLRef, CFDictionaryRef, void *, int))FBGetSymbolFromHandle(handle, "AMDeviceSecureTransferPath");
  FBAMDeviceSecureInstallApplication = (int(*)(int, CFTypeRef, CFURLRef, CFDictionaryRef, void *, int))FBGetSymbolFromHandle(handle, "AMDeviceSecureInstallApplication");
  FBAMDeviceSecureUninstallApplication = (int(*)(int, CFTypeRef, CFStringRef, int, void *, int))FBGetSymbolFromHandle(handle, "AMDeviceSecureUninstallApplication");
  FBAMDeviceLookupApplications = (int(*)(CFTypeRef, CFDictionaryRef, CFDictionaryRef*))FBGetSymbolFromHandle(handle, "AMDeviceLookupApplications");
  FBAMDeviceInstallProvisioningProfile = (int (*)(CFTypeRef, CFTypeRef, void *))FBGetSymbolFromHandle(handle, "AMDeviceInstallProvisioningProfile");
  FBMISProfileCreateWithFile = (CFTypeRef(*)(int, CFStringRef))FBGetSymbolFromHandle(handle, "MISProfileCreateWithFile");
  FBMISProfileCreateWithData = FBGetSymbolFromHandle(handle, "MISProfileCreateWithData");
}

+ (BOOL)AMDinstallProvisioningProfileAtPath:(FBDevice*)fbDevice path:(NSString *)path error:(NSError **)error
{
    [self loadFBAMDeviceSymbols];
    
    NSURL *url = [NSURL fileURLWithPath:path];
    NSData *profileData = [NSData dataWithContentsOfURL:url options:0 error:error];
    
    FBFuture<NSDictionary<NSString *, id> *> * future = [[fbDevice
                                                          connectToDeviceWithPurpose:@"install_provisioning_profile"]
                                                         onQueue:fbDevice.workQueue pop:^(id<FBDeviceCommands> device) {
        ConsoleWriteErr(@"install_provisioning_profile");
        NSURL *url = [NSURL fileURLWithPath:path];
        NSString *encoded = [NSString stringWithUTF8String:[url fileSystemRepresentation]];
        CFStringRef stringRef = (__bridge CFStringRef)encoded;
        CFTypeRef profile = FBMISProfileCreateWithFile(0, stringRef);
        
        //TODO: when these lines will start to work again - all provisioning profile installation legacy functional could be removed
        //            MISProfileRef profile2 = device.calls.ProvisioningProfileCreateWithData((__bridge CFDataRef)(profileData));
        //MISProfileRef profile2 = FBMISProfileCreateWithData((__bridge CFDataRef)(profileData));
        
        if (!profile) {
            return [[FBControlCoreError
                     describeFormat:@"Could not construct profile from data %@", profileData]
                    failFuture];
        }
        int status = device.calls.InstallProvisioningProfile(device.amDeviceRef, profile);
        if (status != 0) {
            NSString *errorDescription = CFBridgingRelease(device.calls.ProvisioningProfileCopyErrorStringForCode(status));
            return [[FBControlCoreError
                     describeFormat:@"Failed to install profile %@: %@", profile, errorDescription]
                    failFuture];
        }
        NSDictionary<NSString *, id> *payload = CFBridgingRelease(device.calls.ProvisioningProfileCopyPayload(profile));
        payload = [FBCollectionOperations recursiveFilteredJSONSerializableRepresentationOfDictionary:payload];
        if (!payload) {
            return [[FBControlCoreError
                     describeFormat:@"Failed to get payload of %@", profile]
                    failFuture];
        }
        return [FBFuture futureWithResult:payload];
    }];
    
    BOOL success = [future await:error] != nil;
    
    return success;
}

////
//functions for installed applications tracking 

//taken from idb. Couldn't been imported - should be tracked.
+ (NSArray <NSString*> *)applicationReturnAttributesDictionary
{
  static NSArray *attrs = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    attrs = @[@"CFBundleIdentifier",
                        @"ApplicationType",
                        @"CFBundleExecutable",
                        @"CFBundleDisplayName",
                        @"CFBundleName",
                        @"CFBundleNumericVersion",
                        @"CFBundleVersion",
                        @"CFBundleShortVersionString",
                        @"CFBundleURLTypes",
                        @"CFBundleDevelopmentRegion",
                        @"Entitlements",
                        @"SignerIdentity",
                        @"ProfileValidated",
                        @"Path",
                        @"Container",
                        @"UIStatusBarTintParameters",
                        @"UIDeviceFamily",
                        @"UISupportedInterfaceOrientations",
                        @"DTPlatformVersion",
                        @"DTXcode",
                        @"MinimumOSVersion"
                        ];
  });
  return attrs;
}

//taken from idb. Couldn't been imported - should be tracked.
+ (FBFuture<NSDictionary<NSString *, NSDictionary<NSString *, id> *> *> *)installedApplicationsData:(FBDevice*)fbDevice returnAttributes:(NSArray<NSString *> *)returnAttributes
{
  return [[fbDevice
    connectToDeviceWithPurpose:@"installed_apps"]
    onQueue:fbDevice.workQueue pop:^ FBFuture<NSDictionary<NSString *, NSDictionary<NSString *, id> *> *> * (id<FBDeviceCommands> device) {
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
+ (NSDictionary *)AMDinstalledApplicationWithBundleIdentifier:(FBDevice*)fbDevice bundleID:(NSString *)bundleID
{
    NSError *error = nil;

    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *apps = [[self installedApplicationsData:fbDevice
                                                                                     returnAttributes:[self applicationReturnAttributesDictionary]] await:&error];
    
    if (!apps){
        return nil;
    }
    
    NSDictionary<NSString *, id> *app = apps[bundleID];
    
    if (!app) {
        return nil;
    }
    
    return app;
}

//was removed in idb, but it's required at this moment
+ (NSString *)containerPathForApplicationWithBundleID:(FBDevice*)fbDevice bundleID:(NSString *)bundleID error:(NSError **)error
{
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *apps = [[self installedApplicationsData:fbDevice returnAttributes: [self applicationReturnAttributesDictionary]] await:error];
    
    if (!apps){
        return nil;
    }
    
    NSDictionary<NSString *, id> *app = apps[bundleID];
    
    if (!app) {
        return nil;
    }
    
    return app[@"Container"];
}

//was removed in idb, but it's required at this moment
+ (NSString *)applicationPathForApplicationWithBundleID:(FBDevice*)fbDevice bundleID:(NSString *)bundleID error:(NSError **)error
{
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *apps = [[self installedApplicationsData:fbDevice returnAttributes: [self applicationReturnAttributesDictionary]] await:error];
    
    if (!apps){
        return nil;
    }
    
    NSDictionary<NSString *, id> *app = apps[bundleID];
    
    if (!app) {
        return nil;
    }
    
    return app[@"Path"];
}


@end
