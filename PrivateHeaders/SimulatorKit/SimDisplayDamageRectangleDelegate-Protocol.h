/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <CoreGraphics/CoreGraphics.h>

#import <SimulatorKit/FoundationXPCProtocolProxyable-Protocol.h>

@protocol SimDisplayDamageRectangleDelegate <FoundationXPCProtocolProxyable>
- (void)didReceiveDamageRect:(struct CGRect)arg1;
@end
