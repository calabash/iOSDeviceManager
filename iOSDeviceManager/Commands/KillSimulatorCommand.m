#import "Simulator.h"
#import "KillSimulatorCommand.h"

@implementation KillSimulatorCommand
+ (NSString *)name {
    return @"kill_simulator";
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
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [Simulator killSimulator:args[DEVICE_ID_FLAG] ?: args[DEVICE_ID_ARGNAME] ?: [Device defaultDeviceID]];
}
@end
