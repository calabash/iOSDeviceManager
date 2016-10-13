
#import "UploadFileCommand.h"

static NSString *const DEVICE_ID_FLAG = @"-d";
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
    return [Device uploadFile:args[FILEPATH_FLAG]
                     toDevice:args[DEVICE_ID_FLAG]
               forApplication:args[BUNDLE_ID_FLAG]
                    overwrite:overwrite];
}
@end
