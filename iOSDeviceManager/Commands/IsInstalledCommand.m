
#import "IsInstalledCommand.h"

static NSString *const BUNDLE_ID_FLAG = @"-b";

@implementation IsInstalledCommand
+ (NSString *)name {
    return @"is_installed";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    
    Device *device;
    @try {
        device = [Device withID:[self deviceIDFromArgs:args]];
    } @catch (NSException *e) {
        return iOSReturnStatusCodeDeviceNotFound;
    }
    
    return [device isInstalled:args[BUNDLE_ID_FLAG]];
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
    });
    return options;
}
@end
