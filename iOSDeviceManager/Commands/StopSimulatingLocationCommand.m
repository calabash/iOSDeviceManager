
#import "StopSimulatingLocationCommand.h"
#import "PhysicalDevice.h"

@implementation StopSimulatingLocationCommand
+ (NSString *)name {
    return @"stop-simulating-location";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    
    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }
    
    return [device stopSimulatingLocation];
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:DEVICE_ID_OPTION_NAME
                                                   info:@"iOS Simulator GUID or 40-digit physical device ID or alias"
                                               required:YES
                                             defaultVal:nil]];
    });
    return options;
}
@end
