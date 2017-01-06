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
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (!([fileManager fileExistsAtPath:pathToBundle] && [pathToBundle hasSuffix:@".app"])) {
        ConsoleWriteErr(@"Could not create application - path to bundle: %@ doesn't exist or not .app", pathToBundle);
        @throw [NSException exceptionWithName:@"InvalidPathException"
                                       reason:@"Invalid path to bundle specified"
                                     userInfo:nil];
    }
    
    app.path = pathToBundle;
    
    NSString *plistPath = [pathToBundle stringByAppendingPathComponent:@"Info.plist"];
    if (![fileManager fileExistsAtPath:plistPath]) {
        ConsoleWriteErr(@"Could not find plist as path: %@", plistPath);
        @throw [NSException exceptionWithName:@"MissingInfoPlistException"
                                       reason:@"Unable to find info plist in path to bundle"
                                     userInfo:nil];
    }
    
    app.infoPlist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    NSString *executableName = app.infoPlist[@"CFBundleExecutable"];
    NSString *executablePath = [pathToBundle stringByAppendingPathComponent:executableName];
    if (![fileManager fileExistsAtPath:executablePath]) {
        ConsoleWriteErr(@"Could not find bundle executable at path: %@", executablePath);
        @throw [NSException exceptionWithName:@"MissingBundleExecutableException"
                                       reason:@"Unable to find bundle executable"
                                     userInfo:nil];
    }
    
    NSError *archError;
    NSSet<NSString *> *arches = [FBBinaryParser architecturesForBinaryAtPath:executablePath error:&archError];
    
    if (archError) {
        ConsoleWriteErr(@"Could not determine app architectures for executable at path: %@ \n with error: %@", executablePath, archError);
        @throw [NSException exceptionWithName:@"UnableToDetermineAppArchitectureException"
                                       reason:@"Unable to determine app architecture"
                                     userInfo:nil];
    }
    
    app.arches = arches;
    
    NSError *productBundleErr;
    FBProductBundle *productBundle = [[[FBProductBundleBuilder builder]
                                      withBundlePath:pathToBundle]
                                      buildWithError:&productBundleErr];
    if (productBundleErr) {
        ConsoleWriteErr(@"Could not determine bundle id for bundle at: %@ \n withError: %@", pathToBundle, productBundleErr);
        @throw [NSException exceptionWithName:@"UnableToDetermineBundleIDException"
                                       reason:@"Unable to determine bundle id for app"
                                     userInfo:nil];
    }
    
    app.bundleID = productBundle.bundleID;

    return app;
}

@end
