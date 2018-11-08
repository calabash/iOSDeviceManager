
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

    NSString *AUTbundleIdOrPath = args[BUNDLE_ID_OPTION_NAME];
    NSString *runnerBundleIdOrPath = args[RUNNER_BUNDLE_ID_OPTION_NAME];
    NSString *runnerPath, *AUTPath = nil;

    if ([AUTbundleIdOrPath isUniformTypeIdentifier]) {
        ConsoleWriteErr(@"Invalid argument: '%@'\n"
                        "Expected a path to an .app bundle.", AUTbundleIdOrPath);
        return iOSReturnStatusCodeInvalidArguments;
    } else {
        NSString *expanded = [FileUtils expandPath:AUTbundleIdOrPath];
        BOOL exists = [Application appBundleOrIpaArchiveExistsAtPath:expanded];
        if (!exists) {
            ConsoleWriteErr(@"AUT .app does not exist at path:\n",
                            AUTbundleIdOrPath);
            return iOSReturnStatusCodeInvalidArguments;
        }
        AUTPath = expanded;
    }

    if ([runnerBundleIdOrPath isUniformTypeIdentifier]) {
        ConsoleWriteErr(@"Invalid argument: '%@'\n"
                        "Expected a path to a -Runner.app bundle.",
                        runnerBundleIdOrPath);
        return iOSReturnStatusCodeInvalidArguments;
    } else {
        NSString *expanded = [FileUtils expandPath:runnerBundleIdOrPath];
        BOOL exists = [Application appBundleOrIpaArchiveExistsAtPath:expanded];
        if (!exists) {
            ConsoleWriteErr(@"-Runner.app does not exist at path:\n",
                            runnerBundleIdOrPath);
            return iOSReturnStatusCodeInvalidArguments;
        }
        runnerPath = expanded;
    }


    iOSReturnStatusCode code;
    code = [device installApp:[Application withBundlePath:AUTPath]
               forceReinstall:YES];
    if (code != iOSReturnStatusCodeEverythingOkay) {
        return iOSReturnStatusCodeInternalError;
    }

    code = [device installApp:[Application withBundlePath:runnerPath]
               forceReinstall:YES];
    if (code != iOSReturnStatusCodeEverythingOkay) {
        return iOSReturnStatusCodeInternalError;
    }

    NSError *error = nil;
    if ([device stageXctestConfigurationToTmpForRunner:runnerPath
                                                   AUT:AUTPath
                                            deviceUDID:device.uuid
                                                 error:&error]) {
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
                                     info:@"path to application under test .app on disk"
                                 required:YES
                               defaultVal:nil],
              [CommandOption withPosition:1
                               optionName:RUNNER_BUNDLE_ID_OPTION_NAME
                                     info:@"path to test -Runner.app on disk"
                                 required:YES
                               defaultVal:nil],
              [CommandOption withShortFlag:DEVICE_ID_FLAG
                                  longFlag:@"--device-id"
                                optionName:DEVICE_ID_OPTION_NAME
                                      info:@"iOS Simulator GUID, physical device ID, or an alias"
                                  required:YES
                                defaultVal:nil]
          ];
    });
    return options;
}

@end
