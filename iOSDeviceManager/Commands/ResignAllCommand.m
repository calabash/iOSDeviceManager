#import "Simulator.h"
#import "ResignCommand.h"
#import "ResignAllCommand.h"
#import "DeviceUtils.h"
#import "AppUtils.h"
#import "FileUtils.h"
#import "Codesigner.h"
#import "ConsoleWriter.h"

static NSString *const OUTPUT_PATH_FLAG = @"-o";
static NSString *const RESOURCES_PATH_FLAG = @"-i";
static NSString *const PROFILES_PATH_OPTION_NAME = @"profiles-directory-path";
static NSString *const APP_PATH_OPTION_NAME = @"app-path";
static NSString *const OUTPUT_PATH_OPTION_NAME = @"output-path";


@implementation ResignAllCommand
+ (NSString *)name {
    return @"resign-all";
}

// Example: resign-all <ipa_file> [-p] <path_to_profiles_dir> -o <out_tar_name> [-i <resources_to_inject>]
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
                                            optionName:PROFILES_PATH_OPTION_NAME
                                                  info:@"Path to profiles directory"
                                              required:YES
                                            defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:OUTPUT_PATH_FLAG
                                               longFlag:@"--output-path"
                                             optionName:OUTPUT_PATH_OPTION_NAME
                                                   info:@"Path to directory to resigned output apps"
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
    NSString *pathToBundle = args[APP_PATH_OPTION_NAME];
    if ([pathToBundle hasSuffix:@".ipa"]) {
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
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL outputIsDirectory = NO;
    if (![fileManager fileExistsAtPath:outputPath isDirectory:&outputIsDirectory] || !outputIsDirectory) {
        ConsoleWriteErr(@"Output path: %@ is not a directory", outputPath);
        return iOSReturnStatusCodeInvalidArguments;
    }
    
    NSString *profilesDir = args[PROFILES_PATH_OPTION_NAME];
    NSArray<MobileProfile *> *profiles;
    
    BOOL profilesIsDirectory = NO;
    if ([fileManager fileExistsAtPath:profilesDir isDirectory:&profilesIsDirectory] && profilesIsDirectory) {
        NSMutableArray<MobileProfile *> *mutableProfiles;
        [FileUtils fileSeq:profilesDir handler:^(NSString *filepath) {
            if ([filepath hasSuffix:@".mobileprovision"]) {
                MobileProfile *profile = [MobileProfile withPath:filepath];
                if (!profile) {
                    ConsoleWriteErr(@"Unable to create mobile profile for profile at: %@", filepath);
                } else {
                    [mutableProfiles addObject:profile];
                }
            }
        }];
        
        profiles = [mutableProfiles copy];
    } else {
        MobileProfile *profile = [MobileProfile withPath:profilesDir];
        if (!profile) {
            ConsoleWriteErr(@"Unable to create mobile profile for profile at: %@", profilesDir);
            return iOSReturnStatusCodeInternalError;
        } else {
            profiles = @[ profile ];
        }
    }
    
    NSArray<NSString *> *resources = [self resourcesFromArgs:args];
    [Codesigner resignApplication:app forProfiles:profiles resourcesToInject:resources resigningHandler:^(Application* app) {
        // Should we assume some naming scheme of resigned ipas?
        NSString *outputFileName = [NSString stringWithFormat:@"resigned-%li.ipa", [app hash]];
        NSString *outputFile = [outputPath stringByAppendingPathComponent:outputFileName];
        [AppUtils zipApp:app to:outputFile];
    }];
    
    return iOSReturnStatusCodeEverythingOkay;
}
@end
