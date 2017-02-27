/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <FBControlCore/FBControlCoreLogger.h>

@class FBApplicationLaunchConfiguration;
@class FBTestManager;
@protocol FBXCTestPreparationStrategy;
@protocol FBiOSTarget;
@protocol FBTestManagerTestReporter;

NS_ASSUME_NONNULL_BEGIN

/**
 Strategy used to run an injected XCTest bundle in an Application and attach the 'testmanagerd' daemon to it.
 */
@interface FBXCTestRunStrategy : NSObject

/**
 Convenience constructor

 @param iosTarget ios target used to run tests.
 @param testPrepareStrategy test preparation strategy used to prepare device to test.
 @param reporter the Reporter to report test progress to.
 @param logger the logger object to log events to, may be nil.
 @return operator
 */
+ (instancetype)strategyWithIOSTarget:(id<FBiOSTarget>)iosTarget testPrepareStrategy:(id<FBXCTestPreparationStrategy>)testPrepareStrategy reporter:(nullable id<FBTestManagerTestReporter>)reporter logger:(nullable id<FBControlCoreLogger>)logger;

/**
 Starts testing session

 @param applicationLaunchConfiguration application launch configuration used to start test runner
 @param error If there is an error, upon return contains an NSError object that describes the problem.
 @return testManager if the operation succeeds, otherwise nil.
 */
- (nullable FBTestManager *)startTestManagerWithApplicationLaunchConfiguration:(FBApplicationLaunchConfiguration *)applicationLaunchConfiguration error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
