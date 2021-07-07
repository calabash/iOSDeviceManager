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

+ (FBWeakFramework *)DevToolsFoundation
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../PlugIns/Xcode3Core.ideplugin/Contents/Frameworks/DevToolsFoundation.framework" requiredClassNames:@[]  requiredFrameworks:@[] rootPermitted:NO];
}

+ (FBWeakFramework *)DevToolsSupport
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../PlugIns/Xcode3Core.ideplugin/Contents/Frameworks/DevToolsSupport.framework" requiredClassNames:@[]  requiredFrameworks:@[] rootPermitted:NO];
}

+ (FBWeakFramework *)DevToolsCore
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../PlugIns/Xcode3Core.ideplugin/Contents/Frameworks/DevToolsCore.framework" requiredClassNames:@[]  requiredFrameworks:@[] rootPermitted:NO];
}


+ (FBWeakFramework *)IBAutolayoutFoundation
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../Frameworks/IBAutolayoutFoundation.framework" requiredClassNames:@[]  requiredFrameworks:@[] rootPermitted:NO];
}

+ (FBWeakFramework *)IDEKit
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../Frameworks/IDEKit.framework" requiredClassNames:@[]  requiredFrameworks:@[] rootPermitted:NO];
}

+ (FBWeakFramework *)DebugHierarchyFoundation
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../SharedFrameworks/DebugHierarchyFoundation.framework" requiredClassNames:@[]  requiredFrameworks:@[] rootPermitted:NO];
}

+ (FBWeakFramework *)DebugHierarchyKit
{
    return [FBWeakFramework xcodeFrameworkWithRelativePath:@"../SharedFrameworks/DebugHierarchyKit.framework" requiredClassNames:@[]  requiredFrameworks:@[] rootPermitted:NO];
}

+ (void)loadPrivateFrameworksOrAbort:(NSArray<FBWeakFramework *> *)frameworks
{
  id<FBControlCoreLogger> logger = FBControlCoreGlobalConfiguration.defaultLogger;
  NSError *error = nil;
    BOOL result = [FBWeakFrameworkLoader loadPrivateFrameworks:frameworks logger:logger error:&error];
  
  if (result) {
    return;
  }
  NSString *message = [NSString stringWithFormat:@"Failed to load private frameworks with error %@", error];

  // Log the message.
  [logger.error log:message];
  // Assertions give a better message in the crash report.
//  NSAssert(NO, message);
  // However if assertions are compiled out, then we still need to abort.
  abort();
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
    
    FBWeakFramework *mobileDeviceFramework = [FBWeakFramework frameworkWithPath:@"/System/Library/PrivateFrameworks/MobileDevice.framework" requiredClassNames:@[]  requiredFrameworks:@[] rootPermitted:NO];

    [frameworks addObject:mobileDeviceFramework];
    
    FBWeakFramework *dtxConnectionFramework = [FBWeakFramework xcodeFrameworkWithRelativePath:@"../SharedFrameworks/DTXConnectionServices.framework" requiredClassNames:@[@"DTXConnection", @"DTXRemoteInvocationReceipt"]  requiredFrameworks:@[] rootPermitted:NO];
    [frameworks addObject:dtxConnectionFramework];
    
    FBWeakFramework *ideFoundationFramework = [FBWeakFramework xcodeFrameworkWithRelativePath:@"../Frameworks/IDEFoundation.framework" requiredClassNames:@[@"IDEFoundationTestInitializer"]  requiredFrameworks:@[] rootPermitted:NO];
    
    [frameworks addObject:ideFoundationFramework];
    
    FBWeakFramework *ideiOSSupportCorePlugin = [FBWeakFramework xcodeFrameworkWithRelativePath:@"../PlugIns/IDEiOSSupportCore.ideplugin" requiredClassNames:@[@"DVTiPhoneSimulator"]  requiredFrameworks:@[
        [self DevToolsFoundation],
        [self DevToolsSupport],
        [self DevToolsCore],
    ] rootPermitted:NO];

    [frameworks addObject:ideiOSSupportCorePlugin];
    
    [frameworks addObject:[self IBAutolayoutFoundation]];
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
//
//        DVTDeviceManager *deviceManager = [objc_lookUpClass("DVTDeviceManager") defaultDeviceManager];
//      DVTiOSDevice *device2;
//
//      NSSet* set = [deviceManager availableDevices];
//        [deviceManager searchForDevicesWithType:nil options:nil timeout:2 error:&err];
//    //    });
//
//        NSArray<DVTiOSDevice *> *devices = [objc_lookUpClass("DVTiOSDevice") alliOSDevices];
//        ConsoleWriteErr(@"devices count: %@", [devices count]);
//    //    NSDictionary<NSString *, DVTiOSDevice *> *dvtDevices = [PhysicalDevice keyDVTDevicesByUDID:[objc_lookUpClass("DVTiOSDevice") alliOSDevices]];
//    //    DVTiOSDevice *dvt = dvtDevices[uuid];

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
    
//    static BOOL success = false;
    
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
        // It seems that searching for a device that does not exist will cause all available devices/simulators etc. to be cached.
        // There's probably a better way of fetching all the available devices, but this appears to work well enough.
        // This means that all the cached available devices can then be found.
        
        DVTDeviceManager *deviceManager = [objc_lookUpClass("DVTDeviceManager") defaultDeviceManager];
        ConsoleWriteErr(@"Quering device manager for %f seconds to cache devices");
        [deviceManager searchForDevicesWithType:nil options:@{@"id" : @"I_DONT_EXIST_AT_ALL"} timeout:2 error:nil];
        ConsoleWriteErr(@"Finished querying devices to cache them");
        //
        //        NSArray<DVTiOSDevice *> *devices = [objc_lookUpClass("DVTiOSDevice") alliOSDevices];
        //        ConsoleWriteErr(@"devices count: %@", [devices count]);
        NSDictionary<NSString *, DVTiOSDevice *> *dvtDevices = [self keyDVTDevicesByUDID:[objc_lookUpClass("DVTiOSDevice") alliOSDevices]];
    
        _dvtDevice = dvtDevices[fbDevice.udid];
        
        NSError *e;
        
        
//        if (!dvtDevice.applications) {
//            [NSRunLoop.currentRunLoop spinRunLoopWithTimeout:2 untilExists:^id{
//                DVTFuture *future = dvtDevice.token.fetchApplications;
//                [future waitUntilFinished];
//                return nil;
//            }];
//        }
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
//    });
}

+ (BOOL)uploadApplicationDataAtPath:(NSString *)path bundleID:(NSString *)bundleID error:(NSError **)error
{
    if(FBLegacy.dvtDevice == nil){
        return NO;
    }
    __block NSError *innerError = nil;
//    BOOL result = [[FBRunLoopSpinner spinUntilBlockFinished:^id{
//      return @([self.dvtDevice uploadApplicationDataWithPath:path forInstalledApplicationWithBundleIdentifier:bundleID error:&innerError]);
//    }] boolValue];
//    *error = innerError;
//    return result;
    
    
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


@end
