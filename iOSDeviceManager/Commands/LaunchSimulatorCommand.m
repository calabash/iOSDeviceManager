
#import "LaunchSimulatorCommand.h"
#import "Simulator.h"
#import "DeviceUtils.h"

@implementation LaunchSimulatorCommand

+ (NSString *)name {
    return @"launch-simulator";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {

    Simulator *simulator = [self simulatorFromArgs:args];
    if (!simulator) {
        return iOSReturnStatusCodeDeviceNotFound;
    }

    return [Simulator launchSimulator:simulator];
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:DEVICE_ID_OPTION_NAME
                                                   info:@"iOS Simulator GUIDs"
                                               required:YES
                                             defaultVal:nil]];
    });
    return options;
}

@end
