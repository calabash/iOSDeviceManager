
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

@interface XCTestConfigurationProxy : NSObject

@property(strong) id configuration;

+ (XCTestConfigurationProxy *)configurationWithContentsOfFile:(NSString *)path;

- (BOOL)writeToPlistFile:(NSString *)path overwrite:(BOOL)overwrite;

@end
