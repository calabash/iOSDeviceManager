
#import "UploadXCAppDataBundleCommand.h"
#import "StringUtils.h"
#import "FileUtils.h"
#import "Application.h"
#import "ConsoleWriter.h"

static NSString *const FILEPATH_OPTION_NAME = @"file-path";

@implementation UploadXCAppDataBundleCommand

+ (NSString *)name {
    return @"upload-xcappdata";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {

    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }

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

    if (![device isInstalled:bundleId withError:nil]) {
        return iOSReturnStatusCodeGenericFailure;
    }

    NSString *path = [FileUtils expandPath:args[FILEPATH_OPTION_NAME]];
    return [device uploadXCAppDataBundle:path
                          forApplication:bundleId];
}

+ (NSArray <CommandOption *> *)options {
    static NSArray<CommandOption *> *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options =
        @[
          [CommandOption withPosition:0
                           optionName:BUNDLE_ID_OPTION_NAME
                                 info:@"bundle identifier or path to .app on disk"
                             required:YES
                           defaultVal:nil],

          [CommandOption withPosition:1
                           optionName:FILEPATH_OPTION_NAME
                                 info:@"the path to the .xcappdata to generate"
                             required:YES
                           defaultVal:nil],

          [CommandOption withShortFlag:DEVICE_ID_FLAG
                              longFlag:@"--device-id"
                            optionName:DEVICE_ID_OPTION_NAME
                                  info:@"iOS Simulator GUID, 40-digit physical device ID, or an alias"
                              required:YES
                            defaultVal:nil]
          ];
    });
    return options;
}

@end
