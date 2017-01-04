#import "Application.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "ConsoleWriter.h"
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import <XCTestBootstrap/XCTestBootstrap.h>

@implementation Application

+ (Application *)withBundlePath:(NSString *)pathToBundle {
    Application *app = [[Application alloc] init];
    app.path = pathToBundle;
    
    NSString *plistPath = [pathToBundle stringByAppendingPathComponent:@"Info.plist"];
    app.infoPlist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    NSString *executableName = app.infoPlist[@"CFBundleExecutable"];
    NSString *executablePath = [pathToBundle stringByAppendingPathComponent:executableName];
    
    ShellResult *result = [ShellRunner xcrun:@[@"lipo", @"-info", executablePath] timeout: 10];
    
    if ([result success]) {
        // Parse lipo result
        // Example: Architectures in the fat file: TestiOSApp are: armv7 arm64
        // Example: Non-fat file: NativeSampleApp is architecture: x86_64
        NSString *lipoResult = [result stdoutStr];
        NSString *rawArches = [[lipoResult componentsSeparatedByString:@":"] lastObject];
        app.arches = [rawArches componentsSeparatedByString:@" "];
        if ([rawArches containsString:@"arm"]) {
            NSError *productBundleErr;
            FBProductBundle *productBundle = [[[FBProductBundleBuilder builder]
                                        withBundlePath:pathToBundle]
                                       buildWithError:&productBundleErr];
            if (productBundle) {
                app.bundleID = productBundle.bundleID;
            } else {
                ConsoleWriteErr(@"Could not determine bundle id for path:\n %@ \n withError: %@", pathToBundle, productBundleErr);
            }
        } else {
            NSError *appDescriptorErr;
            FBApplicationDescriptor *appDescriptor = [FBApplicationDescriptor applicationWithPath:pathToBundle error:&appDescriptorErr];
            
            if (appDescriptor) {
                app.bundleID = appDescriptor.bundleID;
            } else {
                ConsoleWriteErr(@"Could not determine bundle id for path:\n %@ \n withError: %@", pathToBundle, appDescriptorErr);
            }
        }
    } else {
        ConsoleWriteErr(@"Could not find architectures bundle path:\n    %@", pathToBundle);
    }

    return app;
}

@end
