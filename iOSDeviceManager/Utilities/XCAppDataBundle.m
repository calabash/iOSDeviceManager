
#import "XCAppDataBundle.h"
#import "FileUtils.h"
#import "ConsoleWriter.h"

@implementation XCAppDataBundle

+ (NSArray *)sourceDirectoriesForSimulator:(NSString *)path {
    NSString *appData = [path stringByAppendingPathComponent:@"AppData"];
    return @[[appData stringByAppendingPathComponent:@"Documents"],
             [appData stringByAppendingPathComponent:@"Library"],
             [appData stringByAppendingPathComponent:@"tmp"]];
}

+ (BOOL)generateBundleSkeleton:(NSString *)path
                          name:(NSString *) name
                     overwrite:(BOOL)overwrite {
    NSString *expanded = [FileUtils expandPath:path];

    NSError *error = nil;
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![XCAppDataBundle isDirectory:expanded]) {
        if (![manager createDirectoryAtPath:expanded
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&error]) {
            ConsoleWriteErr(@"Cannot create .xcappdata bundle at path:\n  %@\n"
                            "because a directory could not be created:\n  %@",
                            expanded, [error localizedDescription]);
            return NO;
        }
    }

    NSString *bundle = [path stringByAppendingPathComponent:name];

    if ([XCAppDataBundle isDirectory:bundle]) {
        if (!overwrite) {
            ConsoleWriteErr(@"Cannot create app data bundle at path:\n  %@\n"
                            "because a file or directory already exists with that "
                            "name.\n\n"
                            "Use the --overwrite flag to force the creation of a new "
                            "bundle.",
                            bundle);
            return NO;
        }

        if (![manager removeItemAtPath:bundle
                                 error:&error]) {
            ConsoleWriteErr(@"Cannot create app data bundle at path:\n  %@\n"
                            "because a file or directory already exists with that "
                            "name and cannot be removed because:\n%@",
                            bundle, [error localizedDescription]);
            return NO;
        }
    }

    if (![manager createDirectoryAtPath:bundle
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:&error]) {
        ConsoleWriteErr(@"Cannot create app data bundle at path:\n  %@\n"
                        "because .xcappdata directory could not be created:\n%@",
                        bundle, [error localizedDescription]);
        return NO;
    }

    NSString *appData = [bundle stringByAppendingPathComponent:@"AppData"];
    NSArray<NSString *> *directories = @[
                                         [appData stringByAppendingPathComponent:@"Documents"],
                                         [appData stringByAppendingPathComponent:@"tmp"],
                                         [[appData stringByAppendingPathComponent:@"Library"]
                                          stringByAppendingPathComponent:@"Preferences"]
                                         ];

    for (NSString *directory in directories) {
        if (![manager createDirectoryAtPath:directory
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&error]) {
            ConsoleWriteErr(@"Cannot create app data bundle at path:\n %@\n"
                            "because a subdirectory:\n %@\n"
                            "could not be created:\n %@",
                            bundle, directory, [error localizedDescription]);
            return NO;
        }
    }

    if (![XCAppDataBundle isValid:bundle]) {
        ConsoleWriteErr(@"Could not create a valid app data bundle at path:\n  %@",
                        bundle);
        return NO;
    }

    ConsoleWrite(@"%@", bundle);

    return YES;
}

+ (BOOL)isValid:(NSString *)path {
    NSString *expanded = [FileUtils expandPath:path];

    if (![XCAppDataBundle isDirectory:expanded]) {
        ConsoleWriteErr(@"App data bundle:\n  %@\n"
                        "does not exist at path or is not a directory",
                        expanded);
        return NO;
    }

    if (![XCAppDataBundle hasCorrectExtension:expanded]) {
        ConsoleWriteErr(@"App data bundle:\n  %@\nmust have extension .xcappdata",
                        expanded);
        return NO;
    }

    if (![XCAppDataBundle hasAppDataDirectory:expanded]) {
        ConsoleWriteErr(@"App data bundle:\n  %@\nmust have AppData subdirectory",
                        expanded);
        return NO;
    }

    if (![XCAppDataBundle hasDocumentsDirectory:expanded]) {
        ConsoleWriteErr(@"App data bundle:\n  %@\nmust have AppData/Documents subdirectory",
                        expanded);
        return NO;
    }

    if (![XCAppDataBundle hasTmpDirectory:expanded]) {
        ConsoleWriteErr(@"App data bundle:\n  %@\nmust have AppData/tmp subdirectory",
                        expanded);
        return NO;
    }

    if (![XCAppDataBundle hasLibraryDirectory:expanded]) {
        ConsoleWriteErr(@"App data bundle:\n  %@\nmust have AppData/Library subdirectory",
                        expanded);
        return NO;
    }

    if (![XCAppDataBundle hasLibraryPreferencesDirectory:expanded]) {
        ConsoleWriteErr(@"App data bundle:\n  %@\n"
                        "must have AppData/Library/Preferences subdirectory",
                        expanded);
        return NO;
    }
    return YES;
}

+ (BOOL)hasCorrectExtension:(NSString *)path {
    return [[path lastPathComponent] hasSuffix:@".xcappdata"];
}

+ (BOOL)isDirectory:(NSString *)path {
    BOOL directory = NO;
    if ([[NSFileManager defaultManager]
         fileExistsAtPath:path
         isDirectory:&directory]) {
        return directory;
    } else {
        return NO;
    }
}

+ (BOOL)hasSubDirectory:(NSString *)path directory:(NSString *)name {
    BOOL directory = NO;
    NSString *subDir = [path stringByAppendingPathComponent:name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:subDir
                                             isDirectory:&directory]) {
        return directory;
    } else {
        return NO;
    }
}

+ (BOOL)hasSubDirectoryUnderAppData:(NSString *)path directory:(NSString *)name {
    NSString *subDir = [path stringByAppendingPathComponent:@"AppData"];
    return [XCAppDataBundle hasSubDirectory:subDir directory:name];
}

+ (BOOL)hasAppDataDirectory:(NSString *)path {
    return [XCAppDataBundle hasSubDirectory:path directory:@"AppData"];
}

+ (BOOL)hasDocumentsDirectory:(NSString *)path {
    return [XCAppDataBundle hasSubDirectoryUnderAppData:path directory:@"Documents"];
}

+ (BOOL)hasTmpDirectory:(NSString *)path {
    return [XCAppDataBundle hasSubDirectoryUnderAppData:path directory:@"tmp"];
}

+ (BOOL)hasLibraryDirectory:(NSString *)path {
    return [XCAppDataBundle hasSubDirectoryUnderAppData:path directory:@"Library"];
}

+ (BOOL)hasLibraryPreferencesDirectory:(NSString *)path {
    NSString *libDir = [[path stringByAppendingPathComponent:@"AppData"]
                        stringByAppendingPathComponent:@"Library"];
    return [XCAppDataBundle hasSubDirectory:libDir directory:@"Preferences"];
}

@end
