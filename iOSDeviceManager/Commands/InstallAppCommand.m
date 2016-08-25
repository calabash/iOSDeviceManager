
#import "InstallAppCommand.h"

static NSString *const DEVICE_ID_FLAG = @"-d";
static NSString *const APP_BUNDLE_PATH_FLAG = @"-a";
static NSString *const CODESIGN_IDENTITY_FLAG = @"-c";
static NSString *const UPDATE_APP_FLAG = @"-u";

@implementation InstallAppCommand
+ (NSString *)name {
    return @"install";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    BOOL update = [[self optionDict][UPDATE_APP_FLAG].defaultValue boolValue];
    if ([[args allKeys] containsObject:UPDATE_APP_FLAG]) {
        update = [args[UPDATE_APP_FLAG] boolValue];
    }
    return [Device installApp:args[APP_BUNDLE_PATH_FLAG]
                     deviceID:args[DEVICE_ID_FLAG]
                    updateApp:update
                   codesignID:args[CODESIGN_IDENTITY_FLAG]];
}
@end
