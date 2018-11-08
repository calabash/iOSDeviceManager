
#import "LaunchAppCommand.h"

@implementation LaunchAppCommand
+ (NSString *)name {
    return @"launch-app";
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
                                                   info:@"iOS Simulator GUID, physical device ID, or an alias"
                                               required:YES
                                             defaultVal:nil]];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }
    
    return [device launchApp:args[BUNDLE_ID_OPTION_NAME]];
}
@end
