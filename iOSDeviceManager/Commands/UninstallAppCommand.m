
#import "UninstallAppCommand.h"

static NSString *const BUNDLE_ID_FLAG = @"-b";
static NSString *const DEVICE_ID_FLAG = @"-d";

@implementation UninstallAppCommand
+ (NSString *)name {
    return @"uninstall";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [Device uninstallApp:args[BUNDLE_ID_FLAG]
                       deviceID:args[DEVICE_ID_FLAG]];
}
@end
