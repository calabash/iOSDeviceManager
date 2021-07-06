/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/NSObject.h>

#import <SimulatorKit/SimDeviceIOPortConsumer-Protocol.h>
#import <SimulatorKit/SimDisplayDamageRectangleDelegate-Protocol.h>
#import <SimulatorKit/SimDisplayIOSurfaceRenderableDelegate-Protocol.h>
#import <SimulatorKit/SimDisplayRotationAngleDelegate-Protocol.h>

@class NSString, NSUUID;
@protocol OS_dispatch_queue;

@interface SimDisplayConsoleDebugger : NSObject <SimDeviceIOPortConsumer, SimDisplayDamageRectangleDelegate, SimDisplayIOSurfaceRenderableDelegate, SimDisplayRotationAngleDelegate>
{
    CDUnknownBlockType _debugLoggingBlock;
    NSUUID *_consumerUUID;
    NSString *_consumerIdentifier;
    NSObject<OS_dispatch_queue> *_consoleQueue;
}

@property (retain, nonatomic) NSObject<OS_dispatch_queue> *consoleQueue;
@property (nonatomic, copy) NSString *consumerIdentifier;
@property (retain, nonatomic) NSUUID *consumerUUID;
@property (nonatomic, assign) CDUnknownBlockType debugLoggingBlock;

- (void)didReceiveDamageRect:(struct CGRect)arg1;
- (void)didChangeIOSurface:(id)arg1;
- (void)didChangeDisplayAngle:(double)arg1;
- (id)initWithDebugLoggingBlock:(CDUnknownBlockType)arg1;

// Remaining properties
@property (atomic, copy, readonly) NSString *debugDescription;

@end
