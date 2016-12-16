
#import "UninstallAppCommand.h"

static NSString *const BUNDLE_ID_FLAG = @"-b";

@implementation UninstallAppCommand
+ (NSString *)name {
    return @"uninstall";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [Device uninstallApp:args[BUNDLE_ID_FLAG]
                       deviceID:[self deviceIDFromArgs:args]];
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:@"device-identifier"
                                                   info:@"iOS Simulator GUIDs"
                                               required:NO
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:BUNDLE_ID_FLAG
                                               longFlag:@"--bundle-identifier"
                                             optionName:@"bundle-id"
                                                   info:@"bundle identifier (e.g. com.my.app)"
                                               required:YES
                                             defaultVal:nil]];
    });
    return options;
}
@end
