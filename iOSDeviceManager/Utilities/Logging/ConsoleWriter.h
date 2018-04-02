
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

@interface ConsoleWriter : NSObject
+ (void)write:(NSString *)fmt, ...; //Logs to console and file
+ (void)logInfo:(NSString *)fmt, ...; //Logs to file only
+ (void)err:(NSString *)fmt, ...; //Logs to console and file

#define ConsoleWriteErr(fmt, ...) [ConsoleWriter err:fmt,  ##__VA_ARGS__ ]
#define ConsoleWrite(fmt, ...) [ConsoleWriter write:fmt, ##__VA_ARGS__ ]
#define LogInfo(fmt, ...) [ConsoleWriter logInfo:fmt, ##__VA_ARGS__ ]
@end
