/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSimulatorControl/FBSimulatorSet.h>

@class FBSimulatorContainerApplicationLifecycleStrategy;
@class FBSimulatorInflationStrategy;
@class FBSimulatorNotificationUpdateStrategy;

@interface FBSimulatorSet ()

- (instancetype)initWithConfiguration:(FBSimulatorControlConfiguration *)configuration deviceSet:(SimDeviceSet *)deviceSet delegate:(id<FBiOSTargetSetDelegate>)delegate logger:(id<FBControlCoreLogger>)logger reporter:(id<FBEventReporter>)reporter;

@property (nonatomic, strong, readonly) dispatch_queue_t workQueue;
@property (nonatomic, strong, readonly) dispatch_queue_t asyncQueue;
@property (nonatomic, strong, readonly) FBSimulatorInflationStrategy *inflationStrategy;
@property (nonatomic, strong, readonly) FBSimulatorContainerApplicationLifecycleStrategy *containerApplicationStrategy;
@property (nonatomic, strong, readonly) FBSimulatorNotificationUpdateStrategy *notificationUpdateStrategy;

@end
