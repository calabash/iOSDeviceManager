
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
        
        NSAssert([mgr fileExistsAtPath:filePath isDirectory:&isDir],
                 @"Error performing %@ on %@: file does not exist!",
                 NSStringFromSelector(_cmd),
                 filePath);
        if (isDir) {
            [self fileSeq:filePath handler:handler];
        }
    }
}

+ (BOOL)isDylibOrFramework:(NSString *)objectPath {
    return [objectPath hasSuffix:@".framework"] ||
    [objectPath hasSuffix:@".dylib"];
}
@end
