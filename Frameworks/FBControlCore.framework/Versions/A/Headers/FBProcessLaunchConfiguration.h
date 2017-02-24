/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <FBControlCore/FBJSONConversion.h>
#import <FBControlCore/FBDebugDescribeable.h>

@class FBApplicationDescriptor;
@class FBBinaryDescriptor;
@class FBProcessOutputConfiguration;

NS_ASSUME_NONNULL_BEGIN

/**
 An abstract value object for launching both agents and applications
 */
@interface FBProcessLaunchConfiguration : NSObject <NSCopying, NSCoding, FBJSONSerializable, FBDebugDescribeable>

/**
 An NSArray<NSString *> of arguments to the process. Will not be nil.
 */
@property (nonatomic, copy, readonly) NSArray<NSString *> *arguments;

/**
 A NSDictionary<NSString *, NSString *> of the Environment of the launched Application process. Will not be nil.
 */
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *environment;

/**
 The Process Output Configuration.
 */
@property (nonatomic, copy, readonly) FBProcessOutputConfiguration *output;

/**
 Creates a copy of the reciever, with the environment applied.

 @param environment the environment to use.
 @return a copy of the reciever, with the environment applied.
 */
- (instancetype)withEnvironment:(NSDictionary<NSString *, NSString *> *)environment;

/**
 Creates a copy of the reciever, with the arguments applied.

 @param arguments the arguments to use.
 @return a copy of the reciever, with the arguments applied.
 */
- (instancetype)withArguments:(NSArray<NSString *> *)arguments;

@end

/**
 A Value object with the information required to launch an Application.
 */
@interface FBApplicationLaunchConfiguration : FBProcessLaunchConfiguration <FBJSONDeserializable>

/**
 Creates and returns a new Configuration with the provided parameters.

 @param application the Application to Launch.
 @param arguments an NSArray<NSString *> of arguments to the process. Must not be nil.
 @param environment a NSDictionary<NSString *, NSString *> of the Environment of the launched Application process. Must not be nil.
 @param output the output configuration for the launched process.
 @returns a new Configuration Object with the arguments applied.
 */
+ (instancetype)configurationWithApplication:(FBApplicationDescriptor *)application arguments:(NSArray<NSString *> *)arguments environment:(NSDictionary<NSString *, NSString *> *)environment output:(FBProcessOutputConfiguration *)output;

/**
 Creates and returns a new Configuration with the provided parameters.

 @param bundleID the Bundle ID (CFBundleIdentifier) of the App to Launch. Must not be nil.
 @param bundleName the BundleName (CFBundleName) of the App to Launch. May be nil.
 @param arguments an NSArray<NSString *> of arguments to the process. Must not be nil.
 @param environment a NSDictionary<NSString *, NSString *> of the Environment of the launched Application process. Must not be nil.
 @param output the output configuration for the launched process.
 @returns a new Configuration Object with the arguments applied.
 */
+ (instancetype)configurationWithBundleID:(NSString *)bundleID bundleName:(nullable NSString *)bundleName arguments:(NSArray<NSString *> *)arguments environment:(NSDictionary<NSString *, NSString *> *)environment output:(FBProcessOutputConfiguration *)output;

/**
 Adds output configuration.

 @param output output configuration
 @return new application launch configuration with changes applied.
 */
- (instancetype)withOutput:(FBProcessOutputConfiguration *)output;

/**
 The Bundle ID (CFBundleIdentifier) of the the Application to Launch. Will not be nil.
 */
@property (nonnull, nonatomic, copy, readonly) NSString *bundleID;

/**
 The Name (CFBundleName) of the the Application to Launch. May be nil.
 */
@property (nullable, nonatomic, copy, readonly) NSString *bundleName;

@end

/**
 A Value object with the information required to launch a Binary Agent.
 */
@interface FBAgentLaunchConfiguration : FBProcessLaunchConfiguration <FBJSONDeserializable>

/**
 Creates and returns a new Configuration with the provided parameters

 @param agentBinary the Binary Path of the agent to Launch. Must not be nil.
 @param arguments an array-of-strings of arguments to the process. Must not be nil.
 @param environment a Dictionary, mapping Strings to Strings of the Environment to set in the launched Application process. Must not be nil.
 @param output the output configuration for the launched process.
 @returns a new Configuration Object with the arguments applied.
 */
+ (instancetype)configurationWithBinary:(FBBinaryDescriptor *)agentBinary arguments:(NSArray<NSString *> *)arguments environment:(NSDictionary<NSString *, NSString *> *)environment output:(FBProcessOutputConfiguration *)output;

/**
 The Binary Path of the agent to Launch.
 */
@property (nonatomic, copy, readonly) FBBinaryDescriptor *agentBinary;

@end

NS_ASSUME_NONNULL_END
