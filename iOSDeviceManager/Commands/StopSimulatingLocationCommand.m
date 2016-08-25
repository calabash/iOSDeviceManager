
#import "StopSimulatingLocationCommand.h"
#import "PhysicalDevice.h"

static NSString *const DEVICE_ID_FLAG = @"-d";

@implementation StopSimulatingLocationCommand
+ (NSString *)name {
    return @"stop_simulating_location";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [PhysicalDevice stopSimulatingLocation:args[DEVICE_ID_FLAG]];
}
@end
