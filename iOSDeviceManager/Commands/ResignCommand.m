#import "Simulator.h"
#import "ResignCommand.h"
#import "DeviceUtils.h"
#import "Codesigner.h"
#import "AppUtils.h"
#import "ConsoleWriter.h"
#import "FileUtils.h"

static NSString *const APP_PATH_FLAG = @"-a";
static NSString *const PROFILE_PATH_FLAG = @"-p";
static NSString *const OUTPUT_PATH_FLAG = @"-o";
static NSString *const RESOURCES_PATH_FLAG = @"-i";

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
        [options addObject:[CommandOption withShortFlag:APP_PATH_FLAG
                                               longFlag:@"--app-path"
                                             optionName:@"path/to/app.ipa"
                                                   info:@"Path to .ipa"
                                               required:NO
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:PROFILE_PATH_FLAG
                                               longFlag:@"--profile-path"
                                             optionName:@"path/to/profile.mobileprovision"
                                                   info:@"Path to provisioning profile"
                                               required:YES
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:OUTPUT_PATH_FLAG
                                               longFlag:@"--output-path"
                                             optionName:@"path/to/resigned-output.ipa"
                                                   info:@"Path to resign output app"
                                               required:YES
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:RESOURCES_PATH_FLAG
                                               longFlag:@"--resources-path"
                                             optionName:@"path/to/resources"
                                                   info:@"Path to resources to inject"
                                               required:NO
                                             defaultVal:nil]];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    NSString *pathToBundle= args[APP_PATH_FLAG];
    if ([args[APP_PATH_FLAG] hasSuffix:@".ipa"]) {
        pathToBundle = [AppUtils unzipIpa:args[APP_PATH_FLAG]];
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
    NSString *outputPath = args[OUTPUT_PATH_FLAG];
    NSString *profilePath = args[PROFILE_PATH_FLAG];
    NSString *resourcesPath = args[RESOURCES_PATH_FLAG];
    
    MobileProfile *profile;
    profile = [MobileProfile withPath:profilePath];
    
    if (!profile) {
        ConsoleWriteErr(@"Unable to determine mobile profile");
        return iOSReturnStatusCodeInternalError;
    }
    
    if (resourcesPath.length) {
        NSArray<NSString *> *resources;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        BOOL isDirectory = NO;
        if (![fileManager fileExistsAtPath:resourcesPath isDirectory:&isDirectory]) {
            ConsoleWriteErr(@"No directory or file at: %@", resourcesPath);
            return iOSReturnStatusCodeInvalidArguments;
        }
        if (isDirectory) {
            NSMutableArray<NSString *> *mutableResources;
            [FileUtils fileSeq:resourcesPath handler:^(NSString *filepath) {
                BOOL isInnerDirectory = NO;
                if ([fileManager fileExistsAtPath:filepath isDirectory:&isInnerDirectory] && !isInnerDirectory) {
                    [mutableResources addObject:filepath];
                }
            }];

            resources = [mutableResources copy];
        } else {
            resources = @[resourcesPath];
        }
        
        [Codesigner resignApplication:app withProvisioningProfile:profile resourcesToInject:resources];
    } else {
        [Codesigner resignApplication:app withProvisioningProfile:profile];
    }
    
    [AppUtils zipApp:app to:outputPath];
    return iOSReturnStatusCodeEverythingOkay;
}
@end
