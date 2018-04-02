
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

@interface ShasumProvider : NSObject
+ (NSString *)sha1FromData:(NSData *)data;
@end
