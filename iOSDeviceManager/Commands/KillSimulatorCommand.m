
#import "Simulator.h"
#import "KillSimulatorCommand.h"

static NSString *const DEVICE_ID_FLAG = @"-d";

@implementation KillSimulatorCommand
+ (NSString *)name {
    return @"kill_simulator";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [Simulator killSimulator:args[DEVICE_ID_FLAG]];
}
@end
