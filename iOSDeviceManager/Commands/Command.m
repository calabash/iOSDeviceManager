
#import "iOSDeviceManagementCommand.h"
#import "Command.h"
#import "IsInstalledCommand.h"
#import "AppInfoCommand.h"
#import "ClearAppDataCommand.h"
#import "DownloadXCAppDataCommand.h"
#import "CLI.h"
#import "ConsoleWriter.h"
#import "Device.h"
#import "DeviceUtils.h"
#import "FileUtils.h"

NSString *const HELP_SHORT_FLAG = @"-h";
NSString *const HELP_LONG_FLAG = @"--help";
NSString *const DEVICE_ID_FLAG = @"-d";
NSString *const BUNDLE_ID_OPTION_NAME = @"bundle-identifier";
NSString *const DEVICE_ID_OPTION_NAME = @"device-identifier";
NSString *const CODESIGN_ID_OPTION_NAME = @"codesign-identifier";
NSString *const RESOURCES_PATH_OPTION_NAME = @"resources-path";

@implementation Command
static NSMutableDictionary <NSString *, NSDictionary<NSString *, CommandOption *> *> *classOptionDictMap;

+ (NSArray<NSString *> *)resourcesFromArgs:(NSDictionary *)args {
    NSString *resourcePaths = args[RESOURCES_PATH_OPTION_NAME];
    if (resourcePaths.length) {
        // Separate list of paths by colon
        NSArray<NSString *> *resources = [resourcePaths componentsSeparatedByString:@":"];
        NSMutableArray<NSString *> *mutableResourcePaths = [NSMutableArray array];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        for (NSString *resource in resources) {
            NSString *resourcePath = [FileUtils expandPath:resource];
            if (![fileManager fileExistsAtPath:resourcePath]) {
                @throw [NSException exceptionWithName:@"InvalidArgumentException"
                                               reason:@"The specified resource for injection does not exist"
                                             userInfo:nil];
            }
            [mutableResourcePaths addObject:resourcePath];
        }

        return [NSArray arrayWithArray:mutableResourcePaths];
    }
    
    return @[];
}

+ (Device *)deviceFromArgs:(NSDictionary *)args {
    NSString *deviceID = args[DEVICE_ID_OPTION_NAME] ?: [DeviceUtils defaultDeviceID];
    return [Device withID:deviceID];
}

+ (Device *)simulatorFromArgs:(NSDictionary *)args {
    NSString *deviceID = args[DEVICE_ID_OPTION_NAME] ?: [DeviceUtils defaultSimulatorID];
    
    if (![DeviceUtils isSimulatorID:deviceID]) {
        @throw [NSException exceptionWithName:@"InvalidArgumentException"
                                       reason:@"The specified device id does not match a simulator id"
                                       userInfo:nil];
    }
    
    return [Device withID:deviceID];
}

+ (CodesignIdentity *)codesignIDFromArgs:(NSDictionary *)args {
    NSString *codesignID = args[CODESIGN_ID_OPTION_NAME];
    
    if (!codesignID.length) {
        return nil;
    }
    
    if ([codesignID isEqualToString:@"-"]) {
        return [CodesignIdentity adHoc];
    }
    
    CodesignIdentity *codesignIdentity = [CodesignIdentity identityForShasumOrName:codesignID];
    if (codesignIdentity) {
        return codesignIdentity;
    }
    
    return nil;
}

+ (NSString *)name {
    @throw [NSException exceptionWithName:@"ProgrammerErrorException"
                                   reason:@"+(NSString *)name should be overidden by subclass"
                                 userInfo:@{@"this class" : NSStringFromClass(self.class)}];
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    @throw [NSException exceptionWithName:@"ProgrammerErrorException"
                                   reason:@"+(iOSReturnStatusCode *)execute: should be overidden by sublass"
                                 userInfo:@{@"this class" : NSStringFromClass(self.class)}];
}

+ (void)load {
    static dispatch_once_t oncet;
    dispatch_once(&oncet, ^{
        classOptionDictMap = [NSMutableDictionary dictionary];
    });
}

+ (void)validateConformsToProtocol {
    if (![self conformsToProtocol:@protocol(iOSDeviceManagementCommand)]) {
        @throw [NSException exceptionWithName:@"ProgrammerErrorException"
                                       reason:@"Commands should conform to iOSDeviceManagementCommand protocol"
                                     userInfo:nil];
    }
}

+ (id<iOSDeviceManagementCommand>)command {
    [self validateConformsToProtocol];
    return (id<iOSDeviceManagementCommand>)self;
}

+ (NSString *)usage {
    id <iOSDeviceManagementCommand> cmd = [self command];
    NSMutableString *usage = [NSMutableString string];
    [usage appendFormat:@"\n\t%@", [cmd name]];

    for (CommandOption *op in [self positionalOptions]) {
        [usage appendFormat:@" <%@>", op.optionName];

        if (([[cmd name] isEqualToString:[IsInstalledCommand name]]
            || [[cmd name] isEqualToString:[AppInfoCommand name]]
            || [[cmd name] isEqualToString:[ClearAppDataCommand name]]
            || [[cmd name] isEqualToString:[DownloadXCAppDataCommand name]])
            && [op.optionName isEqualToString:BUNDLE_ID_OPTION_NAME]) {
            [usage appendString:@" OR"];
        }
    }

    [usage appendString:@"\n"];

    NSArray<CommandOption *> *flaggedOptions = [self flaggedOptions];
    for (CommandOption *op in flaggedOptions) {
        [usage appendFormat:@"\t\t%@,%@\t<%@>", op.shortFlag, op.longFlag, op.optionName];
        if (!op.required) {
            [usage appendString:@" [OPTIONAL] "];
        }
        if (op.additionalInfo && ![op.additionalInfo isEqualToString:@""]) {
            [usage appendFormat:@"\t%@", op.additionalInfo];
        }
        if (op.defaultValue) {
            [usage appendFormat:@"\tDEFAULT=%@", op.defaultValue];
        }
        if (op != [flaggedOptions lastObject]) {
            [usage appendString:@"\n"];
        }
    }

    return usage;
}

+ (void)printUsage {
    [ConsoleWriter write:@"%@", [self usage]];
}

+ (CommandOption *)optionForFlag:(NSString *)flag {
    id <iOSDeviceManagementCommand> cmd = [self command];
    
    for (CommandOption *op in [cmd options]) {
        if ([op.shortFlag isEqualToString:flag]) {
            return op;
        }
        if ([op.longFlag isEqualToString:flag]) {
            return op;
        }
    }
    
    CommandOption *helpCommand = [CommandOption withShortFlag:HELP_SHORT_FLAG
                                                     longFlag:HELP_LONG_FLAG
                                                   optionName:@"help"
                                                         info:@"prints help"
                                                     required:NO
                                                   defaultVal:@NO].asBooleanOption;
    
    if ([flag isEqualToString:HELP_SHORT_FLAG] ||
        [flag isEqualToString:HELP_LONG_FLAG]) {
        return helpCommand;
    }
    return nil;
}

+ (NSArray<CommandOption *> *)positionalOptions {
    id <iOSDeviceManagementCommand> cmd = [self command];
    NSMutableArray *options = [[NSMutableArray alloc] init];

    for (CommandOption *op in [cmd options]) {
        if (op.positional) {
            [options addObject:op];
        }
    }

    return [options copy];
}

+ (NSArray<CommandOption *> *)flaggedOptions {
    id <iOSDeviceManagementCommand> cmd = [self command];
    NSMutableArray *options = [[NSMutableArray alloc] init];

    for (CommandOption *op in [cmd options]) {
        if (!op.positional) {
            [options addObject:op];
        }
    }

    return [options copy];
}

+ (CommandOption *)optionForPosition:(NSUInteger)index {
    id <iOSDeviceManagementCommand> cmd = [self command];

    for (CommandOption *op in [cmd options]) {
        if (op.positional && op.position == index) {
            return op;
        }
    }

    return nil;
}

+ (CommandOption *)optionForAppPathOrBundleID:(NSString *)arg {
    id <iOSDeviceManagementCommand> cmd = [self command];

    if ([arg hasSuffix:@".app"] || [arg hasSuffix:@".ipa"]) {
        return [cmd options][1];
    }

    return [cmd options].firstObject;
}

+ (NSDictionary <NSString *, CommandOption *> *)optionDict {
    if (classOptionDictMap[self.name] == nil) {
        NSArray <CommandOption *> *options = [self options];
        NSMutableDictionary <NSString *, CommandOption *> *optionsDict
            = [NSMutableDictionary dictionaryWithCapacity:options.count];
        for (CommandOption *opt in options) {
            optionsDict[opt.shortFlag] = opt;
        }
        classOptionDictMap[self.name] = optionsDict;
    }
    return classOptionDictMap[self.name];
}

+ (NSArray <CommandOption *> *)options {
    @throw [NSException exceptionWithName:@"ProgrammerErrorException"
                                   reason:@"+(NSArray <CommandOption *> *)options should be overidden by sublass"
                                 userInfo:@{@"this class" : NSStringFromClass(self.class)}];
}

@end
