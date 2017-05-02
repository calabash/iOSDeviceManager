
#import "IsInstalledCommand.h"

@implementation IsInstalledCommand
+ (NSString *)name {
    return @"is-installed";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    
    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
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
                                            required:YES
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
