#import "InstallAppCommand.h"
#import <FBControlCore/FBControlCore.h>
#import "ConsoleWriter.h"
#import "AppUtils.h"
#import "MobileProfile.h"

static NSString *const CODESIGN_ID_FLAG = @"-c";
static NSString *const UPDATE_APP_FLAG = @"-u";
static NSString *const PROFILE_PATH_FLAG = @"-p";
static NSString *const RESOURCES_PATH_FLAG = @"-i";
static NSString *const APP_PATH_OPTION_NAME = @"app-path";
static NSString *const UPDATE_APP_OPTION_NAME = @"should-update-app";
static NSString *const PROFILE_PATH_OPTION_NAME = @"profile-path";

@implementation InstallAppCommand
+ (NSString *)name {
    return @"install";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    BOOL update = [[self optionDict][UPDATE_APP_FLAG].defaultValue boolValue];
    if ([[args allKeys] containsObject:UPDATE_APP_OPTION_NAME]) {
        update = [args[UPDATE_APP_OPTION_NAME] boolValue];
    }
    
    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }
    
    Application *app = [Application withBundlePath:args[APP_PATH_OPTION_NAME]];
    if (!app) {
        ConsoleWriteErr(@"Error creating application object for path: %@", args[APP_PATH_OPTION_NAME]);
        return iOSReturnStatusCodeGenericFailure;
    }
    
    CodesignIdentity *codesignIdentity = [self codesignIDFromArgs:args];
    
    NSString *profilePath = args[PROFILE_PATH_OPTION_NAME];
    MobileProfile *profile;

    if (profilePath) {
        profile = [MobileProfile withPath:profilePath];
    }
    
    if (profile && codesignIdentity) {
        ConsoleWriteErr(@"Mobile profile and codesign identity both specified - at most one needed");
        return iOSReturnStatusCodeInvalidArguments;
    }

    NSArray<NSString *> *resources = [self resourcesFromArgs:args];
    if (profile) {
        return [device installApp:app
                    mobileProfile:profile
                resourcesToInject:resources
                     shouldUpdate:update];
    }
    
    if (codesignIdentity) {
        return [device installApp:app
                 codesignIdentity:codesignIdentity
                resourcesToInject:resources
                     shouldUpdate:update];
    }
    
    return [device installApp:app
            resourcesToInject:resources
                 shouldUpdate:update];
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withPosition:0
                                            optionName:APP_PATH_OPTION_NAME
                                                  info:@"Path .app bundle or .ipa"
                                              required:YES
                                            defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:DEVICE_ID_OPTION_NAME
                                                   info:@"iOS Simulator GUID or 40-digit physical device ID"
                                               required:YES
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:UPDATE_APP_FLAG
                                               longFlag:@"--update-app"
                                             optionName:UPDATE_APP_OPTION_NAME
                                                   info:@"When true, will reinstall the app if the device contains an older version than the bundle specified"
                                               required:NO
                                             defaultVal:@(YES)]];
        [options addObject:[CommandOption withShortFlag:PROFILE_PATH_FLAG
                                               longFlag:@"--profile-path"
                                             optionName:PROFILE_PATH_OPTION_NAME
                                                   info:@"Path to provisioning profile"
                                               required:NO
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:CODESIGN_ID_FLAG
                                               longFlag:@"--codesign-identity"
                                             optionName:CODESIGN_ID_OPTION_NAME
                                                   info:@"Identity used to codesign app bundle [device only]. Deprecated - should use profile path."
                                               required:NO
                                             defaultVal:@""]];
        [options addObject:[CommandOption withShortFlag:RESOURCES_PATH_FLAG
                                               longFlag:@"--resources-path"
                                             optionName:RESOURCES_PATH_OPTION_NAME
                                                   info:@"Path to resources (executables) to inject into app directory. A list of colon separated files may be specified."
                                               required:NO
                                             defaultVal:nil]];
    });
    return options;
}
@end
