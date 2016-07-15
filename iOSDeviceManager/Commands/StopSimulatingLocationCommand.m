
#import "StopSimulatingLocationCommand.h"
#import "PhysicalDevice.h"

static NSString *const DEVICE_ID_FLAG = @"-d";

@implementation StopSimulatingLocationCommand
+ (NSString *)name {
    return @"stop_simulating_location";
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:@"device-identifier"
                                                   info:@"iOS Simulator GUID or 40-digit physical device ID"
                                               required:YES]];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [PhysicalDevice stopSimulatingLocation:args[DEVICE_ID_FLAG]];
}
@end
