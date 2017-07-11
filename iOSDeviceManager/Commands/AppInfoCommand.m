#import "AppInfoCommand.h"
#import "ConsoleWriter.h"
#import "JSONUtils.h"

static NSString *const APP_PATH_OPTION_NAME = @"app-path";

@implementation AppInfoCommand

+ (NSString *)name {
    return @"app-info";
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withPosition:0
                                            optionName:BUNDLE_ID_OPTION_NAME
                                                  info:@"bundle identifier (e.g. com.my.app)"
                                              required:NO
                                            defaultVal:nil]];
        [options addObject:[CommandOption withPosition:0
                                            optionName:APP_PATH_OPTION_NAME
                                                  info:@"Path .app bundle or .ipa"
                                              required:NO
                                            defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:DEVICE_ID_OPTION_NAME
                                                   info:@"iOS Simulator GUID or 40-digit physical device ID"
                                               required:NO
                                             defaultVal:nil]];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    if (!args[BUNDLE_ID_OPTION_NAME] && !args[APP_PATH_OPTION_NAME]) {
        [ConsoleWriter write:@"\n bundle identifier or app path is required \n"];
        return iOSReturnStatusCodeMissingArguments;
    }

    Application *app = nil;
    if (!args[BUNDLE_ID_OPTION_NAME]) {
        app = [Application withBundlePath:args[APP_PATH_OPTION_NAME]];
    } else {
        Device *device = [self deviceFromArgs:args];
        if (!device) {
            return iOSReturnStatusCodeDeviceNotFound;
        }
        if (![device isInstalled:args[BUNDLE_ID_OPTION_NAME] withError:nil]) {
            [ConsoleWriter write:@"App must be installed or use app path"];
            return iOSReturnStatusCodeFalse;
        }
        app = [device installedApp:args[BUNDLE_ID_OPTION_NAME]];
        if (!app) {
            return iOSReturnStatusCodeFalse;
        }
    }

    NSDictionary *appInfoDetails = @{
                                     @"BUNDLE_ID" : app.bundleID,
                                     @"EXECUTABLE_NAME" : app.executableName ? : @"",
                                     @"DISPLAY_NAME" : app.displayName ? : @"",
                                     @"BUNDLE_VERSION" : app.bundleVersion ? : @"",
                                     @"BUNDLE_SHORT_VERSION" : app.bundleShortVersion ? : @"",
                                     @"ENTITLEMENTS" : app.entitlements ? : @"",
                                     @"ARCHES" : app.arches.allObjects,
                                     @"APP_PATH" : app.path ? : @""
                                     };
    NSString *json = [appInfoDetails pretty];
    json = [json stringByReplacingOccurrencesOfString:@"\\"
                                           withString:@""];
    ConsoleWrite(@"%@", json);
    return iOSReturnStatusCodeEverythingOkay;
}

@end
