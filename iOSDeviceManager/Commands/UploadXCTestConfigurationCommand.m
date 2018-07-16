
#import "UploadXCTestConfigurationCommand.h"
#import "StringUtils.h"
#import "FileUtils.h"
#import "Application.h"
#import "ConsoleWriter.h"

@implementation UploadXCTestConfigurationCommand

+ (NSString *)name {
    return @"upload-xctestconf";
}

+ (BOOL) prepareBundle:(NSString *)appPath forDevice:(Device *)device {
    if (![device isInstalled:appPath withError:nil]) {
        if ([appPath isUniformTypeIdentifier]) {
            ConsoleWriteErr(@"Application %@ is not installed on device %@. Provide path to a .app bundle or .ipa archive instead",
                            appPath, [device uuid]);
            return NO;
        }
        [device installApp:[Application withBundlePath:[FileUtils expandPath:appPath]] forceReinstall:NO];
    }
    return YES;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }

    NSString *AUTbundleIdOrPath = args[BUNDLE_ID_OPTION_NAME];
    NSString *runnerBundleIdOrPath = args[RUNNER_BUNDLE_ID_OPTION_NAME];
    NSString *AUTBundleId, *runnerBundleId;
    if (![AUTbundleIdOrPath isUniformTypeIdentifier]) {
        NSString *expanded = [FileUtils expandPath:AUTbundleIdOrPath];
        BOOL exists = [Application appBundleOrIpaArchiveExistsAtPath:expanded];
        if (!exists) {
            ConsoleWriteErr(@"The argument:\n  %@\n is not a valid bundle identifier, "
                            "path to a .app bundle, or a .ipa archive", AUTbundleIdOrPath);
            return iOSReturnStatusCodeInvalidArguments;
        }

        AUTBundleId = [[Application withBundlePath:expanded] bundleID];
    } else {
        AUTBundleId = [AUTbundleIdOrPath copy];
    }

    if (![runnerBundleIdOrPath isUniformTypeIdentifier]) {
        NSString *expanded = [FileUtils expandPath:runnerBundleIdOrPath];
        BOOL exists = [Application appBundleOrIpaArchiveExistsAtPath:expanded];
        if (!exists) {
            ConsoleWriteErr(@"The argument:\n  %@\n is not a valid bundle identifier, "
                            "path to a .app bundle, or a .ipa archive", AUTbundleIdOrPath);
            return iOSReturnStatusCodeInvalidArguments;
        }

        runnerBundleId = [[Application withBundlePath:expanded] bundleID];
    } else {
        runnerBundleId = [runnerBundleIdOrPath copy];
    }

    if (![self prepareBundle:AUTbundleIdOrPath forDevice:device] ||
        ![self prepareBundle:runnerBundleIdOrPath forDevice:device]) {
        return iOSReturnStatusCodeInternalError;
    }

    NSError *error = nil;
    if ([device stageXctestConfigurationToTmpForRunnerBundleIdentifier:runnerBundleId AUTBundleIdentifier:AUTBundleId error:&error]) {
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        ConsoleWriteErr(@"%@", error);
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
              [CommandOption withPosition:1
                               optionName:RUNNER_BUNDLE_ID_OPTION_NAME
                                     info:@"runner bundle identifier or path to .app on disk"
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
