
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

@interface NSDictionary (CBXUtils)
- (NSString *)pretty;
- (BOOL)hasKey:(id<NSCopying>)key;
- (BOOL)hasValue:(id)val;
@end

@interface NSArray (CBXUtils)
- (NSString *)pretty;
@end
