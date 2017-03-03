#import "Application.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "ConsoleWriter.h"
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import <XCTestBootstrap/XCTestBootstrap.h>

@implementation Application

+ (Application *)withBundlePath:(NSString *)pathToBundle {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (!([fileManager fileExistsAtPath:pathToBundle] && [pathToBundle hasSuffix:@".app"])) {
        ConsoleWriteErr(@"Could not create application - path to bundle: %@ doesn't exist or not .app", pathToBundle);
        return nil;
    }

    NSString *plistPath = [pathToBundle stringByAppendingPathComponent:@"Info.plist"];
    if (![fileManager fileExistsAtPath:plistPath]) {
        ConsoleWriteErr(@"Could not find plist as path: %@", plistPath);
        return nil;
    }

    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:plistPath];

    NSString *executableName = infoPlist[@"CFBundleExecutable"];
    NSString *executablePath = [pathToBundle stringByAppendingPathComponent:executableName];
    if (![fileManager fileExistsAtPath:executablePath]) {
        ConsoleWriteErr(@"Could not find bundle executable at path: %@", executablePath);
        return nil;
    }

    NSError *archError;
    NSSet<NSString *> *arches = [FBBinaryParser architecturesForBinaryAtPath:executablePath error:&archError];

    if (archError) {
        ConsoleWriteErr(@"Could not determine app architectures for executable at path: %@ \n with error: %@", executablePath, archError);
        return nil;
    }

    NSError *productBundleErr;
    FBProductBundle *productBundle = [[[FBProductBundleBuilder builder]
                                      withBundlePath:pathToBundle]
                                      buildWithError:&productBundleErr];
    if (productBundleErr) {
        ConsoleWriteErr(@"Could not determine bundle id for bundle at: %@ \n withError: %@", pathToBundle, productBundleErr);
        return nil;
    }


    Application *app = [self withBundleID:productBundle.bundleID
                                    plist:infoPlist
                            architectures:arches];
    app.path = pathToBundle;
    return app;
}

+ (Application *)withBundleID:(NSString *)bundleID plist:(NSDictionary *)plist architectures:(NSSet *)architectures {
    Application *app = [Application new];
    app.bundleID = bundleID;
    app.infoPlist = plist;
    app.arches = architectures;

    if ([architectures containsObject:@"x86_64"] ||
        [architectures containsObject:@"i386"]) {
        app.type = kApplicationTypeSimulator;
    } else if ([architectures containsObject:@"arm"] ||
               [architectures containsObject:@"armv7"] ||
               [architectures containsObject:@"armv7s"] ||
               [architectures containsObject:@"arm64"]) {
        app.type = kApplicationTypePhysicalDevice;
    } else {
        app.type = kApplicationTypeUnknown;
    }

    return app;
}

- (NSString *)baseDir {
    NSString *dir = [self.path stringByDeletingLastPathComponent];
    NSString *parentDirname = [dir lastPathComponent];
    if ([parentDirname isEqualToString:@"Payload"]) {
        //It's an unzipped ipa: /path/to/somewhere/Payload/MyApp.app
        //We want to return '/path/to/somewhere'
        return [dir stringByDeletingLastPathComponent];
    } else {
        //It's a simulator app or .app outside of a Payload context.
        //We just return the parent dir.
        return dir;
    }
}


@end
