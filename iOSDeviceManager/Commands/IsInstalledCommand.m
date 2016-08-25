
#import "IsInstalledCommand.h"

static NSString *const BUNDLE_ID_FLAG = @"-b";
static NSString *const DEVICE_ID_FLAG = @"-d";

@implementation IsInstalledCommand
+ (NSString *)name {
    return @"is_installed";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [Device appIsInstalled:args[BUNDLE_ID_FLAG]
                         deviceID:args[DEVICE_ID_FLAG]];
}
@end
