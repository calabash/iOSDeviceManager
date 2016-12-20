#import "InstallAppCommand.h"
#import <FBControlCore/FBControlCore.h>
#import "ConsoleWriter.h"

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

    NSError *e;
    FBApplicationDescriptor *app = [FBApplicationDescriptor applicationWithPath:args[APP_BUNDLE_PATH_FLAG] error:&e];
    if (e) {
        ConsoleWriteErr(@"Error creating app bundle for %@: %@", args[APP_BUNDLE_PATH_FLAG], e);
        return iOSReturnStatusCodeGenericFailure;
    }
    
    return [[Device withID:[self deviceIDFromArgs:args]] installApp:app updateApp:update];
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:@"device-identifier"
                                                   info:@"iOS Simulator GUIDs"
                                               required:NO
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:APP_BUNDLE_PATH_FLAG
                                               longFlag:@"--app-bundle"
                                             optionName:@"path/to/app-bundle.app"
                                                   info:@"Path .app bundle (for .ipas, unzip and look inside of 'Payload')"
                                               required:YES
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:CODESIGN_IDENTITY_FLAG
                                               longFlag:@"--codesign-identity"
                                             optionName:@"codesign-identity"
                                                   info:@"Identity used to codesign app bundle [device only]"
                                               required:NO
                                             defaultVal:@""]];
        [options addObject:[CommandOption withShortFlag:UPDATE_APP_FLAG
                                               longFlag:@"--update-app"
                                             optionName:@"true-or-false"
                                                   info:@"When true, will reinstall the app if the device contains an older version than the bundle specified"
                                               required:NO
                                             defaultVal:@(YES)]];
    });
    return options;
}
@end
