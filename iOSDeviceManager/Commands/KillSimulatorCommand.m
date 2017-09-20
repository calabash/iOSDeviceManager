
#import "KillSimulatorCommand.h"
#import "Simulator.h"
#import "ConsoleWriter.h"

@implementation KillSimulatorCommand
+ (NSString *)name {
    return @"kill-simulator";
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:DEVICE_ID_OPTION_NAME
                                                   info:@"iOS Simulator UDID"
                                               required:NO
                                             defaultVal:nil]];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    if (args[DEVICE_ID_OPTION_NAME]) {
        ConsoleWriteErr(@"This command no longer takes a --device-id argument");
        ConsoleWriteErr(@"This command terminates the Simulator.app and requests that all"
                        "simulators shutdown");
        ConsoleWriteErr(@"In a future release, passing a --device-id argument will result"
                        "in a failure");
    }

    return [Simulator killSimulatorApp];
}

@end
