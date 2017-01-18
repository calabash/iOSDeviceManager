
#import "UploadFileCommand.h"

static NSString *const BUNDLE_ID_FLAG = @"-b";
static NSString *const FILEPATH_FLAG = @"-f";
static NSString *const OVERWRITE_FLAG = @"-o";

@implementation UploadFileCommand
+ (NSString *)name {
    return @"upload";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    BOOL overwrite = [[self optionDict][OVERWRITE_FLAG].defaultValue boolValue];
    if ([[args allKeys] containsObject:OVERWRITE_FLAG]) {
        overwrite = [args[OVERWRITE_FLAG] boolValue];
    }

    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }
    
    return [device uploadFile:args[FILEPATH_FLAG] forApplication:args[BUNDLE_ID_FLAG] overwrite:overwrite];
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:BUNDLE_ID_FLAG
                                               longFlag:@"--bundle-identifier"
                                             optionName:@"bundle-id"
                                                   info:@"bundle identifier (e.g. com.my.app)"
                                               required:YES
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:@"device-identifier"
                                                   info:@"iOS Simulator GUIDs"
                                               required:NO
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:FILEPATH_FLAG
                                               longFlag:@"--filepath"
                                             optionName:@"filepath"
                                                   info:@"absolute path to file to be uploaded"
                                               required:YES
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:OVERWRITE_FLAG
                                               longFlag:@"--overwrite"
                                             optionName:@"overwrite"
                                                   info:@"overwrite file if already in app container"
                                               required:NO
                                             defaultVal:@(NO)]];
    });
    return options;
}
@end
