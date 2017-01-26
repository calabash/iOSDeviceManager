#import "Simulator.h"
#import "ResignCommand.h"
#import "DeviceUtils.h"
#import "Codesigner.h"
#import "AppUtils.h"
#import "ConsoleWriter.h"

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
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:@"device-identifier"
                                                   info:@"iOS Simulator GUIDs"
                                               required:NO
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:APP_PATH_FLAG
                                               longFlag:@"--app-path"
                                             optionName:@"path/to/app.ipa"
                                                   info:@"Path to .ipa"
                                               required:YES
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:PROFILE_PATH_FLAG
                                               longFlag:@"--profile-path"
                                             optionName:@"path/to/profile.mobileprovision"
                                                   info:@"Path to provisioning profile"
                                               required:NO
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
    
    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }

    // Should output path be optional?
    NSString *outputPath = args[OUTPUT_PATH_FLAG];
    NSString *profilePath = args[PROFILE_PATH_FLAG];
    NSString *resourcesPath = args[RESOURCES_PATH_FLAG];
    
    MobileProfile *profile;
    if (profilePath.length) {
        profile = [MobileProfile withPath:profilePath];
    } else {
        profile = [MobileProfile bestMatchProfileForApplication:app device:device];
    }
    
    if (!profile) {
        ConsoleWriteErr(@"Unable to determine mobile profile");
        return iOSReturnStatusCodeInternalError;
    }
    
    if (resourcesPath.length) {
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL *isDirectory;
        if (![fileManager fileExistsAtPath:resourcesPath isDirectory:isDirectory]) {
            ConsoleWriteErr(@"No directory at: %@", resourcesPath);
            return iOSReturnStatusCodeInvalidArguments;
        }
        if (!isDirectory) {
            ConsoleWriteErr(@"Resources path: %@ is not a directory: %@", resourcesPath);
            return iOSReturnStatusCodeInvalidArguments;
        }
        
        NSError *contentsError;
        NSArray<NSString *> *resources = [fileManager contentsOfDirectoryAtPath:resourcesPath error:&contentsError];
        if (contentsError) {
            ConsoleWriteErr(@"Error getting resources from dir: %@", resourcesPath);
            return iOSReturnStatusCodeInternalError;
        }
        
        [Codesigner resignApplication:app withProvisioningProfile:profile resourcesToInject:resources];
        // TODO zip up to output path
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        [Codesigner resignApplication:app withProvisioningProfile:profile];
        // TODO zip up to output path
        return iOSReturnStatusCodeEverythingOkay;
    }
}
@end
