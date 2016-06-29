
#import "UninstallAppCommand.h"

static NSString *const BUNDLE_ID_FLAG = @"-b";
static NSString *const DEVICE_ID_FLAG = @"-d";

@implementation UninstallAppCommand
+ (NSString *)name {
    return @"uninstall";
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
                                               required:YES]];
        
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:@"device_identifier"
                                                   info:@"iOS Simulator GUID or 40-digit physical device ID"
                                               required:YES]];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [Device uninstallApp:args[BUNDLE_ID_FLAG]
                       deviceID:args[DEVICE_ID_FLAG]];
}
@end
