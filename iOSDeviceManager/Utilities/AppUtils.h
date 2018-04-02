
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import "Application.h"
#import <Foundation/Foundation.h>

@interface AppUtils : NSObject
+ (BOOL)appVersionIsDifferent:(NSDictionary *)oldPlist newPlist:(NSDictionary *)newPlist;
+ (NSString *)copyAppBundleToTmpDir:(NSString *)bundlePath;
+ (NSString *)unzipToTmpDir:(NSString*)ipaPath;
+ (NSString *)baseDirFromAppDir:(NSString *)appDir;
+ (void)zipApp:(Application *)app to:(NSString *)outputPath;
@end
