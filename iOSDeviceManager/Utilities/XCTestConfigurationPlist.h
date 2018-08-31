
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

@interface XCTestConfigurationPlist : NSObject

+ (NSString *)plistWithXCTestInstallPath:(NSString *)testInstallPath
                             AUTHostPath:(NSString *)autInstallPath
                     AUTBundleIdentifier:(NSString *)autBundleIdentifier
                          runnerHostPath:(NSString *)runnerInstallPath
                  runnerBundleIdentifier:(NSString *)runnerBundleIdentifier
                       sessionIdentifier:(NSString *)UUID;

+ (NSString *)template;

@end
