/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <FBControlCore/FBControlCore.h>

@class FBApplicationLaunchConfiguration;
@class FBSimulator;

NS_ASSUME_NONNULL_BEGIN

/**
 Wraps the 'SimulatorBridge' Connection and Protocol
 */
@interface FBSimulatorBridge : NSObject <FBJSONSerializable>

#pragma mark Initializers

/**
 Creates and Returns a SimulatorBridge for the attaching to the provided Simulator.
 Fails if the connection could not established.

 @param simulator the Simulator to attach to.
 @param error an error out for any error that occurs.
 @return a FBSimulatorBridge object on success, nil otherwise.
 */
+ (nullable instancetype)bridgeForSimulator:(FBSimulator *)simulator error:(NSError **)error;

/**
 Should be called when the connection to the remote bridge should be disconnected.
 */
- (void)disconnect;

#pragma mark Interacting with the Simulator

/**
 The Acessibility Elements.

 @return the Available Accessibility Elements.
 */
- (NSArray<NSDictionary<NSString *, id> *> *)accessibilityElements;

/**
 Enables Accessibility on the Simulator.
 */
- (void)enableAccessibility;

/**
 Sets latitude and longitude of the Simulator.
 The behaviour of a directly-launched Simulator differs from Simulator.app slightly, in that the location isn't automatically set.
 Simulator.app will typically set a location from NSUserDefaults, so Applications will have a default location.

 @param latitude the latitude of the location.
 @param longitude the longitude of the location.
 */
- (void)setLocationWithLatitude:(double)latitude longitude:(double)longitude;

/**
 Launches an Application.

 @param configuration the Configuration of the App to Launch,
 @param stdOutPath the Path of a File to write stdout to.
 @param stdErrPath the path of a File to write stderr to.
 @return the Process Identifeir of the Launched Application if successful, -1 otherwise.
 */
- (pid_t)launch:(FBApplicationLaunchConfiguration *)configuration stdOutPath:(nullable NSString *)stdOutPath stdErrPath:(nullable NSString *)stdErrPath error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
