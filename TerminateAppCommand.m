
#import "TerminateAppCommand.h"
#import "PhysicalDevice.h"

static NSString *const BUNDLE_ID_FLAG = @"-b";
static NSString *const DEVICE_ID_FLAG = @"-d";

@implementation TerminateAppCommand
+ (NSString *)name {
    return @"terminate_app";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [PhysicalDevice terminateApp:args[BUNDLE_ID_FLAG] deviceID:args[DEVICE_ID_FLAG]];
}

@end
