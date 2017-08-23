
#import "GenerateXCAppDataCommand.h"

static NSString *const OVERWRITE_FLAG = @"-o";
static NSString *const OVERWRITE_OPTION_NAME = @"overwrite";
static NSString *const FILEPATH_OPTION_NAME = @"file-path";

@implementation GenerateXCAppDataCommand

+ (NSString *)name {
    return @"generate-xcappdata";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    BOOL overwrite = [[self optionDict][OVERWRITE_FLAG].defaultValue boolValue];
    if ([[args allKeys] containsObject:OVERWRITE_OPTION_NAME]) {
        overwrite = [args[OVERWRITE_OPTION_NAME] boolValue];
    }

    return [Device generateXCAppDataBundleAtPath:args[FILEPATH_OPTION_NAME]
                                       overwrite:overwrite];
}

+ (NSArray <CommandOption *> *)options {
    static NSArray<CommandOption *> *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options =
        @[
          [CommandOption withPosition:0
                           optionName:FILEPATH_OPTION_NAME
                                 info:@"the path to the .xcappdata to generate"
                             required:YES
                           defaultVal:nil],

          [CommandOption withShortFlag:OVERWRITE_FLAG
                              longFlag:@"--overwrite"
                            optionName:OVERWRITE_OPTION_NAME
                                  info:@"overwrite existing .xcappdata directory"
                              required:NO
                            defaultVal:@(NO)]
          ];
    });
    return options;
}

@end
