
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

@interface Stack : NSObject

@property (nonatomic, assign, readonly) NSUInteger count;

- (id)initWithArray:(NSArray*)array;
- (void)pushObject:(id)object;
- (void)pushObjects:(NSArray*)objects;
- (id)popObject;

@end
