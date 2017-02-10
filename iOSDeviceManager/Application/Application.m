#import "Application.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "ConsoleWriter.h"
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import <XCTestBootstrap/XCTestBootstrap.h>

@implementation Application

+ (Application *)withBundlePath:(NSString *)pathToBundle {
    Application *app = [Application new];
    NSString *path = [pathToBundle stringByStandardizingPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (!([fileManager fileExistsAtPath:path] && [path hasSuffix:@".app"])) {
        ConsoleWriteErr(@"Could not create application - path to bundle: %@ doesn't exist or not .app", path);
        return nil;
    }
    
    app.path = path;
    
    NSString *plistPath = [path stringByAppendingPathComponent:@"Info.plist"];
    if (![fileManager fileExistsAtPath:plistPath]) {
        ConsoleWriteErr(@"Could not find plist as path: %@", plistPath);
        return nil;
    }
    
    app.infoPlist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    NSString *executableName = app.infoPlist[@"CFBundleExecutable"];
    NSString *executablePath = [path stringByAppendingPathComponent:executableName];
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
    
    app.arches = arches;
    
    NSError *productBundleErr;
    FBProductBundle *productBundle = [[[FBProductBundleBuilder builder]
                                      withBundlePath:path]
                                      buildWithError:&productBundleErr];
    if (productBundleErr) {
        ConsoleWriteErr(@"Could not determine bundle id for bundle at: %@ \n withError: %@", path, productBundleErr);
        return nil;
    }
    
    app.bundleID = productBundle.bundleID;

    return app;
}

+ (Application *)withBundleID:(NSString *)bundleID plist:(NSDictionary *)plist architectures:(NSSet *)architectures {
    Application *app = [Application new];
    app.bundleID = bundleID;
    app.infoPlist = plist;
    app.arches = architectures;
    
    return app;
}


@end
