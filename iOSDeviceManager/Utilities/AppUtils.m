
#import "AppUtils.h"
#import "ShellRunner.h"

@implementation AppUtils

+ (id)valueForKeyOrThrow:(NSDictionary *)plist key:(NSString *)key {
    NSAssert([[plist allKeys] containsObject:key], @"Missing required key '%@' in plist: %@", key, plist);
    return plist[key];
}

+ (BOOL)appVersionIsDifferent:(NSDictionary *)oldPlist newPlist:(NSDictionary *)newPlist {
    NSString *oldShortVersionString = [self valueForKeyOrThrow:oldPlist key:@"CFBundleShortVersionString"];
    NSString *oldBundleVersion = [self valueForKeyOrThrow:oldPlist key:@"CFBundleVersion"];

    NSString *newShortVersionString = [self valueForKeyOrThrow:newPlist key:@"CFBundleShortVersionString"];
    NSString *newBundleVersion = [self valueForKeyOrThrow:newPlist key:@"CFBundleVersion"];

    if (![oldShortVersionString isEqualToString:newShortVersionString] ||
        ![oldBundleVersion isEqualToString:newBundleVersion]) {
        return YES;
    }

    return NO;
}

+ (NSString *)copyAppBundle:(NSString *)bundlePath {
    NSError *error;
    NSString *UUID = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:UUID];

    if (![[NSFileManager defaultManager] createDirectoryAtPath:tempPath
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error]) {
        DDLogError(@"Could not create directory at path:\n    %@", tempPath);
        DDLogError(@"while trying to copy an app bundle:\n    %@", bundlePath);
        DDLogError(@"%@", [error localizedDescription]);
        return nil;
    }

    NSString *newBundlePath = [tempPath stringByAppendingPathComponent:bundlePath.lastPathComponent];

    if (![[NSFileManager defaultManager] copyItemAtPath:bundlePath
                                                 toPath:newBundlePath
                                                  error:&error]) {
        DDLogError(@"Could not copy app bundle:\n    %@", bundlePath);
        DDLogError(@"to tmp directory:\n    %@", newBundlePath);
        DDLogError(@"%@", [error localizedDescription]);
        return nil;
    }

    return newBundlePath;
}

@end
