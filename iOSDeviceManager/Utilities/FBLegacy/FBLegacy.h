//
//  FBLegacy.h
//  iOSDeviceManager
//
//  Created by Алан Максвелл on 07.07.2021.
//  Copyright © 2021 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConsoleWriter.h"
#import "FBDependentDylib+ApplePrivateDylibs.h"

#import <IDEFoundation/IDEFoundationTestInitializer.h>
#import <DVTFoundation/DVTPlatform.h>
#import <DVTFoundation/DVTDeviceType.h>
#import <IDEiOSSupportCore/DVTiOSDevice.h>
#import <DVTFoundation/DVTDeviceManager.h>

NS_ASSUME_NONNULL_BEGIN

///**
// Contains some functional that was removed from FBSimulatorControl
// but which still reqiired by iOSDeviceManager
// */
@interface FBLegacy : NSObject

/*
 description
 */
+ (void)fetchApplications:(FBDevice *)fbDevice;
/*
 description
 */
+ (BOOL)downloadApplicationDataToPath:(NSString *)path bundleID:(NSString *)bundleID error:(NSError **)error;
/*
 description
 */
+ (BOOL)uploadApplicationDataAtPath:(NSString *)path bundleID:(NSString *)bundleID error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
