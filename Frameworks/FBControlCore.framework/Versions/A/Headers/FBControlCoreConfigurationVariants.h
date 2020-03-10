/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

/* Portions Copyright © Microsoft Corporation. */

#import <Foundation/Foundation.h>

#import <FBControlCore/FBArchitecture.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Uses the known values of SimDeviceType ProductFamilyID, to construct an enumeration.
 These mirror the values from -[SimDeviceState productFamilyID].
 */
typedef NS_ENUM(NSUInteger, FBControlCoreProductFamily) {
  FBControlCoreProductFamilyUnknown = 0,
  FBControlCoreProductFamilyiPhone = 1,
  FBControlCoreProductFamilyiPad = 2,
  FBControlCoreProductFamilyAppleTV = 3,
  FBControlCoreProductFamilyAppleWatch = 4,
};

/**
 Device Names Enumeration.
 */
typedef NSString *FBDeviceModel NS_STRING_ENUM;

extern FBDeviceModel const FBDeviceModeliPhone8A;
extern FBDeviceModel const FBDeviceModeliPhone8PlusB;
extern FBDeviceModel const FBDeviceModeliPhoneXC;

extern FBDeviceModel const FBDeviceModeliPhone4s;
extern FBDeviceModel const FBDeviceModeliPhone5;
extern FBDeviceModel const FBDeviceModeliPhone5c;
extern FBDeviceModel const FBDeviceModeliPhone5s;
extern FBDeviceModel const FBDeviceModeliPhone6;
extern FBDeviceModel const FBDeviceModeliPhone6Plus;
extern FBDeviceModel const FBDeviceModeliPhone6S;
extern FBDeviceModel const FBDeviceModeliPhone6SPlus;
extern FBDeviceModel const FBDeviceModeliPhoneSE;
extern FBDeviceModel const FBDeviceModeliPhone7;
extern FBDeviceModel const FBDeviceModeliPhone7Plus;
extern FBDeviceModel const FBDeviceModeliPhone8;
extern FBDeviceModel const FBDeviceModeliPhone8Plus;
extern FBDeviceModel const FBDeviceModeliPhoneX;
extern FBDeviceModel const FBDeviceModeliPhoneXS;
extern FBDeviceModel const FBDeviceModeliPhoneXSMax;
extern FBDeviceModel const FBDeviceModeliPhoneXR;
extern FBDeviceModel const FBDeviceModeliPad2;
extern FBDeviceModel const FBDeviceModeliPadRetina;
extern FBDeviceModel const FBDeviceModeliPadAir;
extern FBDeviceModel const FBDeviceModeliPadAir2;
extern FBDeviceModel const FBDeviceModeliPadPro;
extern FBDeviceModel const FBDeviceModeliPadPro_9_7_Inch;
extern FBDeviceModel const FBDeviceModeliPadPro_12_9_Inch;
extern FBDeviceModel const FBDeviceModeliPadPro_9_7_Inch_2ndGeneration;
extern FBDeviceModel const FBDeviceModeliPadPro_12_9_Inch_2ndGeneration;
extern FBDeviceModel const FBDeviceModeliPadPro_10_5_Inch;
extern FBDeviceModel const FBDeviceModeliPad_6thGeneration;
extern FBDeviceModel const FBDeviceModeliPadPro_11_Inch;
extern FBDeviceModel const FBDeviceModeliPadPro_12_9_Inch_3ndGeneration;
extern FBDeviceModel const FBDeviceModelAppleTV;
extern FBDeviceModel const FBDeviceModelAppleTV4K;
extern FBDeviceModel const FBDeviceModelAppleTV4KAt1080p;
extern FBDeviceModel const FBDeviceModelAppleWatch38mm;
extern FBDeviceModel const FBDeviceModelAppleWatch42mm;
extern FBDeviceModel const FBDeviceModelAppleWatchSeries2_38mm;
extern FBDeviceModel const FBDeviceModelAppleWatchSeries2_42mm;
extern FBDeviceModel const FBDeviceModelAppleWatchSeries3_38mm;
extern FBDeviceModel const FBDeviceModelAppleWatchSeries3_42mm;
extern FBDeviceModel const FBDeviceModelAppleWatchSeries4_40mm;
extern FBDeviceModel const FBDeviceModelAppleWatchSeries4_44mm;

/**
 OS Versions Name Enumeration.
 */
typedef NSString *FBOSVersionName NS_STRING_ENUM;

extern FBOSVersionName const FBOSVersionNameiOS_7_1;
extern FBOSVersionName const FBOSVersionNameiOS_8_0;
extern FBOSVersionName const FBOSVersionNameiOS_8_1;
extern FBOSVersionName const FBOSVersionNameiOS_8_2;
extern FBOSVersionName const FBOSVersionNameiOS_8_3;
extern FBOSVersionName const FBOSVersionNameiOS_8_4;
extern FBOSVersionName const FBOSVersionNameiOS_9_0;
extern FBOSVersionName const FBOSVersionNameiOS_9_1;
extern FBOSVersionName const FBOSVersionNameiOS_9_2;
extern FBOSVersionName const FBOSVersionNameiOS_9_3;
extern FBOSVersionName const FBOSVersionNameiOS_9_3_1;
extern FBOSVersionName const FBOSVersionNameiOS_9_3_2;
extern FBOSVersionName const FBOSVersionNameiOS_10_0;
extern FBOSVersionName const FBOSVersionNameiOS_10_1;
extern FBOSVersionName const FBOSVersionNameiOS_10_2;
extern FBOSVersionName const FBOSVersionNameiOS_10_3;
extern FBOSVersionName const FBOSVersionNameiOS_11_0;
extern FBOSVersionName const FBOSVersionNameiOS_11_1;
extern FBOSVersionName const FBOSVersionNameiOS_11_2;
extern FBOSVersionName const FBOSVersionNameiOS_11_3;
extern FBOSVersionName const FBOSVersionNameiOS_11_4;
extern FBOSVersionName const FBOSVersionNameiOS_12_0;
extern FBOSVersionName const FBOSVersionNameiOS_12_1;
extern FBOSVersionName const FBOSVersionNameiOS_12_2;
extern FBOSVersionName const FBOSVersionNameiOS_13_0;
extern FBOSVersionName const FBOSVersionNameiOS_13_1;
extern FBOSVersionName const FBOSVersionNameiOS_13_1_1;
extern FBOSVersionName const FBOSVersionNameiOS_13_1_2;
extern FBOSVersionName const FBOSVersionNameiOS_13_1_3;
extern FBOSVersionName const FBOSVersionNameiOS_13_2_1;
extern FBOSVersionName const FBOSVersionNameiOS_13_3;
extern FBOSVersionName const FBOSVersionNameiOS_13_3_1;
extern FBOSVersionName const FBOSVersionNameiOS_13_4;
extern FBOSVersionName const FBOSVersionNametvOS_9_0;
extern FBOSVersionName const FBOSVersionNametvOS_9_1;
extern FBOSVersionName const FBOSVersionNametvOS_9_2;
extern FBOSVersionName const FBOSVersionNametvOS_10_0;
extern FBOSVersionName const FBOSVersionNametvOS_10_1;
extern FBOSVersionName const FBOSVersionNametvOS_10_2;
extern FBOSVersionName const FBOSVersionNametvOS_11_0;
extern FBOSVersionName const FBOSVersionNametvOS_11_1;
extern FBOSVersionName const FBOSVersionNametvOS_11_2;
extern FBOSVersionName const FBOSVersionNametvOS_11_3;
extern FBOSVersionName const FBOSVersionNametvOS_11_4;
extern FBOSVersionName const FBOSVersionNametvOS_12_0;
extern FBOSVersionName const FBOSVersionNametvOS_12_1;
extern FBOSVersionName const FBOSVersionNametvOS_12_2;
extern FBOSVersionName const FBOSVersionNametvOS_13_0;
extern FBOSVersionName const FBOSVersionNamewatchOS_2_0;
extern FBOSVersionName const FBOSVersionNamewatchOS_2_1;
extern FBOSVersionName const FBOSVersionNamewatchOS_2_2;
extern FBOSVersionName const FBOSVersionNamewatchOS_3_0;
extern FBOSVersionName const FBOSVersionNamewatchOS_3_1;
extern FBOSVersionName const FBOSVersionNamewatchOS_3_2;
extern FBOSVersionName const FBOSVersionNamewatchOS_4_0;
extern FBOSVersionName const FBOSVersionNamewatchOS_4_1;
extern FBOSVersionName const FBOSVersionNamewatchOS_4_2;
extern FBOSVersionName const FBOSVersionNamewatchOS_5_0;
extern FBOSVersionName const FBOSVersionNamewatchOS_5_1;
extern FBOSVersionName const FBOSVersionNamewatchOS_5_2;
extern FBOSVersionName const FBOSVersionNamewatchOS_6_0;

#pragma mark Devices

@interface FBDeviceType : NSObject <NSCopying>

/**
 The Device Name of the Device.
 */
@property (nonatomic, copy, readonly) FBDeviceModel model;

/**
 The String Representations of the Product Types.
 */
@property (nonatomic, copy, readonly) NSSet<NSString *> *productTypes;

/**
 The native Device Architecture.
 */
@property (nonatomic, copy, readonly) FBArchitecture deviceArchitecture;

/**
 The Native Simulator Arhitecture.
 */
@property (nonatomic, copy, readonly) FBArchitecture simulatorArchitecture;

/**
 The Supported Product Family.
 */
@property (nonatomic, assign, readonly) FBControlCoreProductFamily family;

/**
 A Generic Device with the Given Name.
 */
+ (instancetype)genericWithName:(NSString *)name;

@end

#pragma mark OS Versions

@interface FBOSVersion : NSObject <NSCopying>

/**
 The Version name of the OS.
 */
@property (nonatomic, copy, readonly) FBOSVersionName name;

/**
 A Decimal Number Represnting the Version Number.
 */
@property (nonatomic, copy, readonly) NSDecimalNumber *number;

/**
 The Supported Families of the OS Version.
 */
@property (nonatomic, copy, readonly) NSSet<NSNumber *> *families;

/**
 A Generic OS with the Given Name.
 */
+ (instancetype)genericWithName:(NSString *)name;

@end

/**
 Mappings of Variants.
 */
@interface FBControlCoreConfigurationVariants : NSObject

/**
 Maps Device Names to Devices.
 */
@property (class, nonatomic, copy, readonly) NSDictionary<FBDeviceModel, FBDeviceType *> *nameToDevice;

/**
 Maps Device 'ProductType' to Device Variants.
 */
@property (class, nonatomic, copy, readonly) NSDictionary<NSString *, FBDeviceType *> *productTypeToDevice;

/**
 OS Version names to OS Versions.
 */
@property (class, nonatomic, copy, readonly) NSDictionary<FBOSVersionName, FBOSVersion *> *nameToOSVersion;

/**
 Maps the architechture of the target to the compatible architechtures for binaries on the target.
 */
@property (class, nonatomic, copy, readonly) NSDictionary<FBArchitecture, NSSet<FBArchitecture> *> *baseArchToCompatibleArch;

@end

NS_ASSUME_NONNULL_END

