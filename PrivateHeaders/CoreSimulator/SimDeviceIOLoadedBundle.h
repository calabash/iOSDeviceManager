/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class NSBundle;
@protocol SimDeviceIOBundleInterface;

@interface SimDeviceIOLoadedBundle : NSObject
{
    NSBundle *_bundle;
    id<SimDeviceIOBundleInterface> _bundleInterface;
}

+ (id)loadedBundleForURL:(id)arg1;
@property (retain, nonatomic) id<SimDeviceIOBundleInterface> bundleInterface;
@property (retain, nonatomic) NSBundle *bundle;

- (id)initWithURL:(id)arg1;

@end
