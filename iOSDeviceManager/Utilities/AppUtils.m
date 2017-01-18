
#import "AppUtils.h"
#import "ShellRunner.h"
#import "ConsoleWriter.h"
#import "ShellResult.h"

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

+ (NSString *)copyAppBundleToTmpDir:(NSString *)bundlePath {
    NSError *error;
    NSString *UUID = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:UUID];

    if (![[NSFileManager defaultManager] createDirectoryAtPath:tempPath
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error]) {
        ConsoleWriteErr(@"Could not create directory at path:\n    %@", tempPath);
        ConsoleWriteErr(@"while trying to copy an app bundle:\n    %@", bundlePath);
        ConsoleWriteErr(@"%@", [error localizedDescription]);
        return nil;
    }

    NSString *newBundlePath = [tempPath stringByAppendingPathComponent:bundlePath.lastPathComponent];

    if (![[NSFileManager defaultManager] copyItemAtPath:bundlePath
                                                 toPath:newBundlePath
                                                  error:&error]) {
        ConsoleWriteErr(@"Could not copy app bundle:\n    %@", bundlePath);
        ConsoleWriteErr(@"to tmp directory:\n    %@", newBundlePath);
        ConsoleWriteErr(@"%@", [error localizedDescription]);
        return nil;
    }

    return newBundlePath;
}

+ (NSString *)unzipIpa:(NSString*)ipaPath {
    NSString *copiedAppPath = [AppUtils copyAppBundleToTmpDir:ipaPath];
    NSString *unzipPath = [copiedAppPath stringByDeletingLastPathComponent];
    NSString *payloadPath = [unzipPath stringByAppendingString:@"/Payload/"];
    NSArray *params = @[@"ditto", @"-xk", copiedAppPath, unzipPath];

    ShellResult *result = [ShellRunner xcrun:params timeout:20];
    if (!result.success) {
        @throw [NSException exceptionWithName:@"Error unzipping ipa"
                                       reason:result.stderrStr
                                     userInfo:nil];
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *bundlePath = nil;
    for (NSString * payloadContent in [fileManager contentsOfDirectoryAtPath:payloadPath error:nil]) {
        if ([payloadContent hasSuffix:@".app"]) {
            bundlePath = [payloadPath stringByAppendingString:payloadContent];
            break;
        }
    }
    
    if (bundlePath == nil) {
        @throw [NSException exceptionWithName:@"Error unzipping ipa"
                                       reason:@"Unable to find Payload/ in unzipped ipa"
                                     userInfo:nil];
    }
    
    return bundlePath;
}

@end
