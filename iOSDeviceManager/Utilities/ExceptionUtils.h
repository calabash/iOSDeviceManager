
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

@interface ExceptionUtils : NSObject
+ (void)throwWithName:(NSString *)name format:(NSString *)fmt, ...;
#define THROW(name, fmt, ...) [ExceptionUtils throwWithName:(name) format:fmt, ##__VA_ARGS__ ]
#define CBXThrowExceptionIf(condition, fmt, ...) if (! (condition) ) { THROW(@"CBXException", fmt, ##__VA_ARGS__); }
@end
