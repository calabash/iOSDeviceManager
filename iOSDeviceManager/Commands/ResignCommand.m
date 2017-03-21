#import "Simulator.h"
#import "ResignCommand.h"
#import "DeviceUtils.h"
#import "Codesigner.h"
#import "AppUtils.h"
#import "ConsoleWriter.h"
#import "FileUtils.h"

static NSString *const OUTPUT_PATH_FLAG = @"-o";
static NSString *const RESOURCES_PATH_FLAG = @"-i";
static NSString *const APP_PATH_OPTION_NAME = @"app-path";
static NSString *const PROFILE_PATH_OPTION_NAME = @"profile-path";
static NSString *const OUTPUT_PATH_OPTION_NAME = @"output-path";

@implementation ResignCommand
+ (NSString *)name {
    return @"resign";
}

// Example: resign <ipa_file> [-p] <path_to_profile> -o <outfilename> [-i <resources_to_inject>]

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withPosition:0
                                            optionName:APP_PATH_OPTION_NAME
                                                  info:@"Path to .ipa"
                                              required:YES
                                            defaultVal:nil]];
        [options addObject:[CommandOption withPosition:1
                                            optionName:PROFILE_PATH_OPTION_NAME
                                                  info:@"Path to provisioning profile"
                                              required:YES
                                            defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:OUTPUT_PATH_FLAG
                                               longFlag:@"--output-path"
                                             optionName:OUTPUT_PATH_OPTION_NAME
                                                   info:@"Path to resign output app"
                                               required:YES
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:RESOURCES_PATH_FLAG
                                               longFlag:@"--resources-path"
                                             optionName:RESOURCES_PATH_OPTION_NAME
                                                   info:@"Path to resources to inject"
                                               required:NO
                                             defaultVal:nil]];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    NSString *pathToBundle= args[APP_PATH_OPTION_NAME];
    if ([args[APP_PATH_OPTION_NAME] hasSuffix:@".ipa"]) {
        pathToBundle = [AppUtils unzipToTmpDir:args[APP_PATH_OPTION_NAME]];
    } else {
        ConsoleWriteErr(@"Resigning requires ipa path");
        return iOSReturnStatusCodeInvalidArguments;
    }
    
    Application *app = [Application withBundlePath:pathToBundle];
    if (!app || !app.path) {
        ConsoleWriteErr(@"Error creating application object for path: %@", pathToBundle);
        return iOSReturnStatusCodeGenericFailure;
    }

    // Should output path be optional?
    NSString *outputPath = args[OUTPUT_PATH_OPTION_NAME];
    NSString *profilePath = args[PROFILE_PATH_OPTION_NAME];
    
    MobileProfile *profile;
    profile = [MobileProfile withPath:profilePath];
    
    if (!profile) {
        ConsoleWriteErr(@"Unable to determine mobile profile");
        return iOSReturnStatusCodeInternalError;
    }
    
    NSArray<NSString *> *resources = [self resourcesFromArgs:args];
    if (resources.count > 0) {
        [Codesigner resignApplication:app withProvisioningProfile:profile resourcesToInject:resources];
    } else {
        [Codesigner resignApplication:app withProvisioningProfile:profile];
    }
    
    [AppUtils zipApp:app to:outputPath];
    return iOSReturnStatusCodeEverythingOkay;
}
@end
