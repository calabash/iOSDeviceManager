
#import "AppUtils.h"

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
    NSError *e;
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                          [[NSProcessInfo processInfo] globallyUniqueString]];
    [[NSFileManager defaultManager] createDirectoryAtPath:tempPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&e];
    
    if (e) {
        NSLog(@"Error creating dir at path %@: %@", bundlePath, e);
        return nil;
    }

    NSString *newBundlePath = [tempPath stringByAppendingPathComponent:bundlePath.lastPathComponent];
    [[NSFileManager defaultManager] copyItemAtPath:bundlePath
                                            toPath:newBundlePath
                                             error:&e];
    if (e) {
        NSLog(@"Error copying bundle from %@ to %@: %@", bundlePath, tempPath, e);
        return nil;
    }
    return newBundlePath;
}

@end
