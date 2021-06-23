/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FBProcessIO;

/**
 An abstract value object for launching both agents and applications
 */
@interface FBProcessLaunchConfiguration : NSObject

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
@property (nonatomic, strong, readonly) FBProcessIO *io;

/**
 The Designated Initializer.

 @param arguments the Arguments.
 @param environment the Environment.
 @param io the IO object.
 @return a new FBProcessLaunchConfiguration Instance.
 */
- (instancetype)initWithArguments:(NSArray<NSString *> *)arguments environment:(NSDictionary<NSString *, NSString *> *)environment io:(FBProcessIO *)io;

@end

NS_ASSUME_NONNULL_END
