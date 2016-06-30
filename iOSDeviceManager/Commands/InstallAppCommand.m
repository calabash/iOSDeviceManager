
#import "InstallAppCommand.h"

static NSString *const DEVICE_ID_FLAG = @"-d";
static NSString *const APP_BUNDLE_PATH_FLAG = @"-a";
static NSString *const CODESIGN_IDENTITY_FLAG = @"-c";

@implementation InstallAppCommand
+ (NSString *)name {
    return @"install";
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:CODESIGN_IDENTITY_FLAG
                                               longFlag:@"--codesign-identity"
                                             optionName:@"codesign-identity"
                                                   info:@"Identity used to codesign app bundle [device only]"
                                               required:NO]];
        
        [options addObject:[CommandOption withShortFlag:APP_BUNDLE_PATH_FLAG
                                               longFlag:@"--app-bundle"
                                             optionName:@"path/to/app-bundle.app"
                                                   info:@"Path .app bundle (for .ipas, unzip and look inside of 'Payload')"
                                               required:YES]];
        
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:@"device-identifier"
                                                   info:@"iOS Simulator GUID or 40-digit physical device ID"
                                               required:YES]];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [Device installApp:args[APP_BUNDLE_PATH_FLAG]
                     deviceID:args[DEVICE_ID_FLAG]
                   codesignID:args[CODESIGN_IDENTITY_FLAG]];
}
@end
