
#import "LaunchSimulatorCommand.h"
#import "Simulator.h"

static NSString *const DEVICE_ID_FLAG = @"-d";

@implementation LaunchSimulatorCommand
+ (NSString *)name {
    return @"launch_simulator";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [Simulator launchSimulator:args[DEVICE_ID_FLAG]];
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
                                               required:YES
                                             defaultVal:nil]];
    });
    return options;
}
@end
