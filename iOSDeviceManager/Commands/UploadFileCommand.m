
#import "UploadFileCommand.h"

static NSString *const FILEPATH_FLAG = @"-f";
static NSString *const OVERWRITE_FLAG = @"-o";
static NSString *const FILEPATH_OPTION_NAME = @"file-path";
static NSString *const OVERWRITE_OPTION_NAME = @"overwrite";

@implementation UploadFileCommand
+ (NSString *)name {
    return @"upload";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    BOOL overwrite = [[self optionDict][OVERWRITE_FLAG].defaultValue boolValue];
    if ([[args allKeys] containsObject:OVERWRITE_OPTION_NAME]) {
        overwrite = [args[OVERWRITE_OPTION_NAME] boolValue];
    }

    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }

    if (![device isInstalled:args[BUNDLE_ID_FLAG] withError:nil]) {
        return iOSReturnStatusCodeFalse;
    }

    return [device uploadFile:args[FILEPATH_OPTION_NAME] forApplication:args[BUNDLE_ID_OPTION_NAME] overwrite:overwrite];
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withPosition:0
                                            optionName:FILEPATH_OPTION_NAME
                                                  info:@"path to file to be uploaded"
                                              required:YES
                                            defaultVal:nil]];
        [options addObject:[CommandOption withPosition:1
                                            optionName:BUNDLE_ID_OPTION_NAME
                                                  info:@"bundle identifier (e.g. com.my.app)"
                                              required:YES
                                            defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:DEVICE_ID_OPTION_NAME
                                                   info:@"iOS Simulator GUID or 40-digit physical device ID"
                                               required:YES
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:OVERWRITE_FLAG
                                               longFlag:@"--overwrite"
                                             optionName:OVERWRITE_OPTION_NAME
                                                   info:@"overwrite file if already in app container"
                                               required:NO
                                             defaultVal:@(NO)]];
    });
    return options;
}
@end
