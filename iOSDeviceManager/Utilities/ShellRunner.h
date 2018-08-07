
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import "ShellResult.h"

@interface ShellRunner : NSObject

+ (ShellResult *)command:(NSString *)command
                    args:(NSArray *)args
                 timeout:(NSTimeInterval)timeout;
+ (ShellResult *)xcrun:(NSArray *)args timeout:(NSTimeInterval)timeout;
+ (BOOL)verbose;

@end
