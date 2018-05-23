
#import "UploadXCTestConfigurationCommand.h"
#import "StringUtils.h"
#import "FileUtils.h"
#import "Application.h"
#import "ConsoleWriter.h"

@implementation UploadXCTestConfigurationCommand

+ (NSString *)name {
    return @"upload-xctestconf";
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

    NSError *error = nil;
    if ([device stageXctestConfigurationToTmpForBundleIdentifier:bundleId
                                                           error:&error]) {
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        ConsoleWrite(@"%@", error);
        return iOSReturnStatusCodeGenericFailure;
    }
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

              [CommandOption withShortFlag:DEVICE_ID_FLAG
                                  longFlag:@"--device-id"
                                optionName:DEVICE_ID_OPTION_NAME
                                      info:@"iOS Simulator GUID or 40-digit physical device ID or alias"
                                  required:YES
                                defaultVal:nil]
          ];
    });
    return options;
}

@end
