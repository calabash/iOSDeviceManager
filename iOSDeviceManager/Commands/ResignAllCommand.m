#import "Simulator.h"
#import "ResignAllCommand.h"
#import "DeviceUtils.h"
#import "Codesigner.h"

static NSString *const APP_PATH_FLAG = @"-a";
static NSString *const PROFILE_PATH_FLAG = @"-p";
static NSString *const OUTPUT_PATH_FLAG = @"-o";
static NSString *const RESOURCES_PATH_FLAG = @"-i";

@implementation ResignAllCommand
+ (NSString *)name {
    return @"resign_all";
}

// Example: resign-all <ipa_file> [-p] <path_to_profiles_dir> -o <out_tar_name> [-i <resources_to_inject>]

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
                                               longFlag:@"--profiles-path"
                                             optionName:@"path/to/profiles"
                                                   info:@"Path to profiles directory"
                                               required:NO
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:OUTPUT_PATH_FLAG
                                               longFlag:@"--output-path"
                                             optionName:@"path/to/output"
                                                   info:@"Path to directory to resigned output apps"
                                               required:NO
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
    // TODO
    return iOSReturnStatusCodeGenericFailure;
}
@end
