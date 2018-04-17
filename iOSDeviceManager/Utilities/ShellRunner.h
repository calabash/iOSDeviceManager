
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

@class ShellResult;

@interface ShellRunner : NSObject

+ (NSArray<NSString *> *)shell:(NSString *)cmd args:(NSArray *)args;
+ (NSArray<NSString *> *)xcrun:(NSArray *)args;
+ (ShellResult *)xcrun:(NSArray *)args timeout:(NSTimeInterval)timeout;
+ (NSString *)pwd;
+ (NSString *)tmpDir;
+ (BOOL)verbose;

@end
