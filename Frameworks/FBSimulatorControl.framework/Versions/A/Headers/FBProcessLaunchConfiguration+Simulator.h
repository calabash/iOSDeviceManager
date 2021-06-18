/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBControlCore/FBControlCore.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSimulator;

/**
 Process Launch Configuration for Simulators.
 */
@interface FBProcessLaunchConfiguration (Simulator)

/**
 Builds the CoreSimulator launch Options for Launching an App or Process on a Simulator.

 @param arguments the arguments to use.
 @param environment the environment to use.
 @param waitForDebugger YES if the Application should be launched waiting for a debugger to attach. NO otherwise.
 @return a Dictionary of the Launch Options.
 */
+ (NSMutableDictionary<NSString *, id> *)launchOptionsWithArguments:(NSArray<NSString *> *)arguments environment:(NSDictionary<NSString *, NSString *> *)environment waitForDebugger:(BOOL)waitForDebugger;

@end

/**
 Helpers for Application Launches.
 */
@interface FBApplicationLaunchConfiguration (Helpers)

/**
 Creates the Dictionary of launch options for launching an Application.

 @param stdOutPath the path to launch stdout to, may be nil.
 @param stdErrPath the path to launch stderr to, may be nil.
 @param waitForDebugger YES if the Application should be launched waiting for a debugger to attach. NO otherwise.
 @return a Dictionary if successful, nil otherwise.
 */
- (NSDictionary<NSString *, id> *)simDeviceLaunchOptionsWithStdOutPath:(nullable NSString *)stdOutPath stdErrPath:(nullable NSString *)stdErrPath waitForDebugger:(BOOL)waitForDebugger;

@end

NS_ASSUME_NONNULL_END
