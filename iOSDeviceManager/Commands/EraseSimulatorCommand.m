#import "EraseSimulatorCommand.h"
#import "PhysicalDevice.h"
#import "ConsoleWriter.h"
#import "DeviceUtils.h"

@implementation EraseSimulatorCommand

+ (NSString *)name {
    return @"erase-simulator";
}

+ (NSArray <CommandOption *> *)options {
    static NSArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @[
                    [CommandOption withPosition:0
                                     optionName:DEVICE_ID_OPTION_NAME
                                           info:@"iOS Simulator GUID or 40-digit physical device ID"
                                       required:YES
                                     defaultVal:nil]
                    ];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {

    Device *device = [self deviceFromArgs:args];

    if (!device) {
        if ([DeviceUtils isDeviceID:args[DEVICE_ID_OPTION_NAME]]) {
          ConsoleWriteErr(@"erase-simulator command is only for simulators");
        } else {
          ConsoleWriteErr(@"could not find a simulator that matches udid");
        }
        return iOSReturnStatusCodeDeviceNotFound;
    }

    if ([device isKindOfClass:[PhysicalDevice class]]) {
      ConsoleWriteErr(@"erase-simulator command is only for simulators");
      return iOSReturnStatusCodeDeviceNotFound;
    }

    return [Simulator eraseSimulator:(Simulator *)device];
}

@end
