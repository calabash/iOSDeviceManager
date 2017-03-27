
#import "StringUtils.h"
#import "FileUtils.h"

@implementation FileUtils
+ (void)fileSeq:(NSString *)dir handler:(filePathHandler)handler {
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    NSError *e = nil;
    NSArray *children = [mgr contentsOfDirectoryAtPath:dir error:&e];
    NSAssert(e == nil, @"Unable to enumerate children of %@", dir, e);
    BOOL isDir = NO;
    [mgr fileExistsAtPath:dir isDirectory:&isDir];
    NSAssert(isDir, @"Tried to enumerate children of '%@', but it's not a dir.", dir);
    
    for (NSString *file in children) {
        NSString *filePath = [dir joinPath:file];
        handler(filePath);
        isDir = NO;
        BOOL __unused exists = [mgr fileExistsAtPath:filePath isDirectory:&isDir];
        NSAssert(exists,
                 @"Error performing %@ on %@: file does not exist!",
                 NSStringFromSelector(_cmd),
                 filePath);
        if (isDir) {
            [self fileSeq:filePath handler:handler];
        }
    }
}

/**
 Returns an array of paths in depth first.

 If an error occurs, returns `nil`.
 */
+ (NSArray <NSString *> *)depthFirstPathsStartingAtDirectory:(NSString *)dir error:(NSError **)error {
    NSFileManager *mgr = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![mgr fileExistsAtPath:dir isDirectory:&isDir]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"No file at path: %@", dir];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:msg forKey:NSLocalizedRecoverySuggestionErrorKey];
            *error = [NSError errorWithDomain:@"iOSDeviceManager"
                                         code:NSFileNoSuchFileError
                                     userInfo:userInfo];
        }
        return nil;
    }

    NSMutableArray<NSString *> *files = [[NSMutableArray alloc] init];
    NSMutableArray<NSString *> *directories = [[NSMutableArray alloc] initWithObjects:dir, nil];
    [files addObject:dir]; // Include initial directory
    while (directories.count != 0) {
        NSString *currentDirectory = [directories firstObject];
        [directories removeObjectAtIndex:0];
        NSArray *children = [mgr contentsOfDirectoryAtPath:currentDirectory error:error];
        if (![mgr fileExistsAtPath:currentDirectory isDirectory:&isDir]) { continue; }
        for (NSString *file in children) {
            NSString *filePath = [currentDirectory joinPath:file];
            isDir = NO;
            BOOL exists = [mgr fileExistsAtPath:filePath isDirectory:&isDir];
            if (!exists) { continue; }
            [files addObject:filePath];
            if (isDir) { [directories insertObject:filePath atIndex:0]; }
        }
    }

    return [files copy];
}

+ (BOOL)isDylibOrFramework:(NSString *)objectPath {
    return [objectPath hasSuffix:@".framework"] ||
    [objectPath hasSuffix:@".dylib"];
}

+ (NSString *)expandPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableString *standardPath = [path mutableCopy];
    if ([standardPath hasPrefix:@".."]) {
        NSString *currentDirectory = [fileManager currentDirectoryPath];
        standardPath = [[currentDirectory stringByAppendingPathComponent:standardPath] mutableCopy];
    }
    if ([standardPath hasPrefix:@"."]) {
        NSString *currentDirectory = [fileManager currentDirectoryPath];
        [standardPath replaceOccurrencesOfString:@"."
                                      withString:currentDirectory
                                         options:NSCaseInsensitiveSearch
                                           range:NSMakeRange(0, 1)];
    }
    // Handle possible relative path without preceding ~ .. or .
    if (![standardPath hasPrefix:@"/"] && ![standardPath hasPrefix:@"~"]) {
        NSString *currentDirectory = [fileManager currentDirectoryPath];
        standardPath = [[currentDirectory stringByAppendingPathComponent:standardPath] mutableCopy];
    }
    return [standardPath stringByStandardizingPath];
}
@end
