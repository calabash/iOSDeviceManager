/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBControlCore/FBProcessLaunchConfiguration.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An enum representing how an agent should be launched.
 */
typedef NS_ENUM(NSUInteger, FBAgentLaunchMode) {
  FBAgentLaunchModeDefault = 0,
  FBAgentLaunchModePosixSpawn = 1,
  FBAgentLaunchModeLaunchd = 2,
};

/**
 A Value object with the information required to launch a Binary Agent.
 */
@interface FBAgentLaunchConfiguration : FBProcessLaunchConfiguration

/**
 The designated initializer.

 @param launchPath the path to the executable to launch.
 @param arguments an array-of-strings of arguments to the process. Must not be nil.
 @param environment a Dictionary, mapping Strings to Strings of the Environment to set in the launched Application process. Must not be nil.
 @param output the output configuration for the launched process.
 @param mode the launch mode to use.
 @return a new Configuration Object with the arguments applied.
 */
- (instancetype)initWithLaunchPath:(NSString *)launchPath arguments:(NSArray<NSString *> *)arguments environment:(NSDictionary<NSString *, NSString *> *)environment output:(FBProcessOutputConfiguration *)output mode:(FBAgentLaunchMode)mode;

/**
 The Binary Path of the agent to Launch.
 */
@property (nonatomic, copy, readonly) NSString *launchPath;

/**
 How the agent should be launched.
 */
@property (nonatomic, assign, readonly) FBAgentLaunchMode mode;

@end

NS_ASSUME_NONNULL_END
