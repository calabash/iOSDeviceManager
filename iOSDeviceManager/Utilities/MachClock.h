
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#include <Foundation/Foundation.h>

@interface MachClock : NSObject

+ (instancetype)sharedClock;
- (NSTimeInterval)absoluteTime;

@end
