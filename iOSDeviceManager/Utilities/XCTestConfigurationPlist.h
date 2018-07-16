
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>

@interface XCTestConfigurationPlist : NSObject

+ (NSString *)plistWithXCTestInstallPath:(NSString *)testInstallPath
                          AUTInstalledPath:(NSString *)autInstallPath
                     AUTBundleIdentifier:(NSString *)autBundleIdentifier
                       runnerInstalledPath:(NSString *)runnerInstallPath
                  runnerBundleIdentifier:(NSString *)runnerBundleIdentifier
                       sessionIdentifier:(NSString *)UUID;

@end
