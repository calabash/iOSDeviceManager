
#import "KillAppCommand.h"
#import "PhysicalDevice.h"

static NSString *const BUNDLE_ID_FLAG = @"-b";
static NSString *const DEVICE_ID_FLAG = @"-d";

@implementation KillAppCommand
+ (NSString *)name {
    return @"kill_app";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [PhysicalDevice killApp:args[BUNDLE_ID_FLAG] deviceID:args[DEVICE_ID_FLAG]];
}

@end
