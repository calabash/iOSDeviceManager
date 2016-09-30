/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <FBSimulatorControl/FBSimulatorEventSink.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBCompositeSimulatorEventSink : NSObject <FBSimulatorEventSink>

/**
 A Composite Sink that will notify an array of sinks.

 @param sinks the sinks to call.
 */
+ (instancetype)withSinks:(NSArray<id<FBSimulatorEventSink>> *)sinks;

@end

NS_ASSUME_NONNULL_END
