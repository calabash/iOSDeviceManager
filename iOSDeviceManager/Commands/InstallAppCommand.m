#import "InstallAppCommand.h"
#import <FBControlCore/FBControlCore.h>
#import "ConsoleWriter.h"
#import "AppUtils.h"

static NSString *const APP_PATH_FLAG = @"-a";
static NSString *const CODESIGN_IDENTITY_FLAG = @"-c";
static NSString *const UPDATE_APP_FLAG = @"-u";

@implementation InstallAppCommand
+ (NSString *)name {
    return @"install";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    BOOL update = [[self optionDict][UPDATE_APP_FLAG].defaultValue boolValue];
    if ([[args allKeys] containsObject:UPDATE_APP_FLAG]) {
        update = [args[UPDATE_APP_FLAG] boolValue];
    }
    
    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }
    
    NSString *pathToBundle= args[APP_PATH_FLAG];
    if ([args[APP_PATH_FLAG] hasSuffix:@".ipa"]) {
        pathToBundle = [AppUtils unzipIpa:args[APP_PATH_FLAG]];
    } else {
        pathToBundle = [AppUtils copyAppBundleToTmpDir:args[APP_PATH_FLAG]];
    }
    
    Application *app = [Application withBundlePath:pathToBundle];
    if (!app || !app.path) {
        ConsoleWriteErr(@"Error creating application object for path: %@", pathToBundle);
        return iOSReturnStatusCodeGenericFailure;
    }
    return [device installApp:app shouldUpdate:update];
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:@"device-identifier"
                                                   info:@"iOS Simulator GUIDs"
                                               required:NO
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:APP_PATH_FLAG
                                               longFlag:@"--app-path"
                                             optionName:@"path/to/app-bundle.app or path/to/app.ipa"
                                                   info:@"Path .app bundle or .ipa"
                                               required:YES
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:CODESIGN_IDENTITY_FLAG
                                               longFlag:@"--codesign-identity"
                                             optionName:@"codesign-identity"
                                                   info:@"Identity used to codesign app bundle [device only]"
                                               required:NO
                                             defaultVal:@""]];
        [options addObject:[CommandOption withShortFlag:UPDATE_APP_FLAG
                                               longFlag:@"--update-app"
                                             optionName:@"true-or-false"
                                                   info:@"When true, will reinstall the app if the device contains an older version than the bundle specified"
                                               required:NO
                                             defaultVal:@(YES)]];
    });
    return options;
}
@end
