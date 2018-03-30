#import "ClearAppDataCommand.h"
#import "ConsoleWriter.h"
#import "AppUtils.h"
#import "StringUtils.h"
#import "FileUtils.h"

static NSString *const APP_PATH_OPTION_NAME = @"app-path";

@implementation ClearAppDataCommand

+ (NSString *)name {
    return @"clear-app-data";
}

+ (NSArray <CommandOption *> *)options {
    static NSArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @[ 
            [CommandOption withPosition:0
                             optionName:BUNDLE_ID_OPTION_NAME
                                   info:@"bundle identifier (e.g. com.my.app)"
                               required:NO
                             defaultVal:nil],
            [CommandOption withPosition:0
                             optionName:APP_PATH_OPTION_NAME
                                   info:@"Path .app bundle or .ipa"
                               required:NO
                             defaultVal:nil],
            [CommandOption withPosition:1
                             optionName:DEVICE_ID_OPTION_NAME
                                   info:@"iOS Simulator GUID or 40-digit physical device ID"
                               required:NO
                             defaultVal:nil]
        ];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    if (!args[BUNDLE_ID_OPTION_NAME] && !args[APP_PATH_OPTION_NAME]) {
        [ConsoleWriter write:@"\n bundle identifier or app path is required \n"];
        return iOSReturnStatusCodeMissingArguments;
    }
    
    Device *device = nil;
    NSString *bundleId = args[BUNDLE_ID_OPTION_NAME];
    if (![bundleId isUniformTypeIdentifier]) {
        NSString *expanded = [FileUtils expandPath:bundleId];
        if (![Application appBundleOrIpaArchiveExistsAtPath:expanded]) {
            ConsoleWriteErr(@"The first argument:\n  %@\n is not a valid bundle identifier, "
                            "path to a .app bundle, or a .ipa archive", bundleId);
            return iOSReturnStatusCodeInvalidArguments;
        }
        
        bundleId = [[Application withBundlePath:expanded] bundleID];
    }
    
    device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }
    
    if (![device isInstalled:bundleId withError:nil]) {
        [ConsoleWriter write:@"App must be installed or use app path"];
        return iOSReturnStatusCodeFalse;
    }
    
    [Device generateXCAppDataBundleAtPath:@"Empty.xcappdata" overwrite:YES];
    
    [device uploadXCAppDataBundle:@"Empty.xcappdata" forApplication:bundleId];

    return iOSReturnStatusCodeEverythingOkay;
}


@end
