
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

@interface NSString (CBXUtils)

- (NSString *)replace:(NSString *)subs with:(NSString *)replacement;
- (NSString *)subsFrom:(NSUInteger)start length:(NSUInteger)length;
- (NSString *)plus:(NSString *)ending;
- (NSString *)joinPath:(NSString *)pathComponent;
- (NSArray <NSString *> *)matching:(NSString *)regex;

/**
 A uniform type identifier is also known as a reverse DNS bundle identifier
 @return true if this string is a bundle identifier
 */
- (BOOL)isUniformTypeIdentifier;

@end
