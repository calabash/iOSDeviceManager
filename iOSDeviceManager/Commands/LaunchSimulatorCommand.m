
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
@end
