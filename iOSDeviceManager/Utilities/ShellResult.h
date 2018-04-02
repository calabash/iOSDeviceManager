
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

@interface ShellResult : NSObject

+ (ShellResult *)withTask:(NSTask *) task
                  elapsed:(NSTimeInterval)elapsed
               didTimeOut:(BOOL)didTimeout;
+ (ShellResult *)withFailedCommand:(NSString *)command
                           elapsed:(NSTimeInterval)elapsed;

- (BOOL)didTimeOut;
- (NSTimeInterval)elapsed;
- (NSString *)command;
- (BOOL)success;
- (NSInteger)exitStatus;
- (NSString *)stdoutStr;
- (NSString *)stderrStr;
- (NSArray<NSString *> *)stdoutLines;
- (void)logStdoutAndStderr;

@end
