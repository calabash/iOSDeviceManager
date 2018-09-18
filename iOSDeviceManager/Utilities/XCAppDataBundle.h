
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

@interface XCAppDataBundle : NSObject

+ (BOOL)isValid:(NSString *)expanded;
+ (NSString *)generateBundleSkeleton:(NSString *)path
                                name:(NSString *) name
                           overwrite:(BOOL)overwrite;

+ (NSArray *)sourceDirectoriesForSimulator:(NSString *)path;

@end
