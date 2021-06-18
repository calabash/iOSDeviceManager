/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBControlCore/FBControlCore.h>

#import <FBSimulatorControl/FBAgentLaunchStrategy.h>

NS_ASSUME_NONNULL_BEGIN

@class FBApplicationLaunchConfiguration;
@class FBProcessInfo;
@class FBProcessOutput;

/**
 An Operation for an Agent.
 This class is explicitly a reference type as it retains the File Handles that are used by the Agent Process.
 The lifecycle of the process is managed internally and this class should not be instantiated directly by consumers.
 */
@interface FBSimulatorAgentOperation : NSObject <FBLaunchedProcess>

#pragma mark Properties

/**
 The Configuration Launched with.
 */
@property (nonatomic, copy, readonly) FBAgentLaunchConfiguration *configuration;

/**
 The stdout File Handle.
 */
@property (nonatomic, strong, nullable, readonly) FBProcessOutput *stdOut;

/**
 The stderr File Handle.
 */
@property (nonatomic, strong, nullable, readonly) FBProcessOutput *stdErr;

@end

/**
 Private methods that should not be called by consumers.
 */
@interface FBSimulatorAgentOperation (Private)

/**
 The Designated Initializer.

 @param simulator the Simulator the Agent is launched in.
 @param configuration the configuration the process was launched with.
 @param stdOut the Stdout output.
 @param stdErr the Stderr output.
 @param launchFuture a future that will fire when the process has launched. The value is the process identifier.
 @param processStatusFuture a future that will fire when the process has terminated. The value is that of waitpid(2).
 @return a Future that resolves when the process is launched.
 */
+ (FBFuture<FBSimulatorAgentOperation *> *)operationWithSimulator:(FBSimulator *)simulator configuration:(FBAgentLaunchConfiguration *)configuration stdOut:(nullable FBProcessOutput *)stdOut stdErr:(nullable FBProcessOutput *)stdErr launchFuture:(FBFuture<NSNumber *> *)launchFuture processStatusFuture:(FBFuture<NSNumber *> *)processStatusFuture;

@end

NS_ASSUME_NONNULL_END
