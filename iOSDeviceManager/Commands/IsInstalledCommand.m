
#import "IsInstalledCommand.h"
#import "ConsoleWriter.h"

static NSString *const APP_PATH_OPTION_NAME = @"app-path";

@implementation IsInstalledCommand
+ (NSString *)name {
    return @"is-installed";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    
    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }

    if (!args[BUNDLE_ID_OPTION_NAME] && !args[APP_PATH_OPTION_NAME]) {
        [self printUsage];
        [ConsoleWriter write:@"\n bundle identifier or app path (for convenience) is required \n"];
        return iOSReturnStatusCodeMissingArguments;
    }

    if (!args[BUNDLE_ID_OPTION_NAME]) {
        Application *app = [Application withBundlePath:args[APP_PATH_OPTION_NAME]];
        [ConsoleWriter write:@"Using app path for convenience %@ with bundle id: %@ \n",
                                args[APP_PATH_OPTION_NAME], app.bundleID];
        return [device isInstalled:app.bundleID];
    }
    
    return [device isInstalled:args[BUNDLE_ID_OPTION_NAME]];
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
                                                  info:@"path/to/app"
                                              required:NO
                                            defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:DEVICE_ID_OPTION_NAME
                                                   info:@"iOS Simulator GUID or 40-digit physical device ID"
                                               required:YES
                                             defaultVal:nil]];
    });
    return options;
}
@end
