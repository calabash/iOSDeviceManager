
#import "iOSDeviceManagementCommand.h"
#import "Command.h"
#import "CLI.h"
#import "ConsoleWriter.h"
#import "Device.h"
#import "DeviceUtils.h"
#import "FileUtils.h"

NSString *const HELP_SHORT_FLAG = @"-h";
NSString *const HELP_LONG_FLAG = @"--help";
NSString *const DEVICE_ID_FLAG = @"-d";
NSString *const APP_ID_FLAG = @"-a";
NSString *const PROFILE_PATH_FLAG = @"-p";
NSString *const RESOURCES_PATH_FLAG = @"-i";
NSString *const CODESIGN_ID_FLAG = @"-c";
NSString *const RESIGN_OBJECT_PATH_FLAG = @"-ro";
NSString *const PROFILE_PATH_ARGNAME = @"profile_path";
NSString *const DEVICE_ID_ARGNAME = @"device_id";
NSString *const APP_ID_ARGNAME = @"app_id";
NSString *const CODESIGN_ID_ARGNAME = @"codesign_id";
NSString *const RESIGN_OBJECT_ARGNAME = @"resign_object";

@implementation Command
static NSMutableDictionary <NSString *, NSDictionary<NSString *, CommandOption *> *> *classOptionDictMap;

+ (NSString *)positionalArgShortFlag:(NSString *)arg {
    if ([arg hasSuffix:@".app"] || [arg hasSuffix:@".ipa"]) {
        return APP_ID_FLAG;
    }
    
    if ([arg hasSuffix:@".mobileprovision"]) {
        return PROFILE_PATH_FLAG;
    }
    
    if ([DeviceUtils isSimulatorID:arg] || [DeviceUtils isDeviceID:arg]) {
        return DEVICE_ID_FLAG;
    }
    
    if ([FileUtils isDylibOrFramework:arg]) {
        return RESIGN_OBJECT_PATH_FLAG;
    }
    
    if ([arg isEqualToString:@"-"] || [CodesignIdentity isValidCodesignIdentity:arg]) {
        return CODESIGN_ID_FLAG;
    }
    
    return nil;
}

+(NSArray <NSString *> *) positionalArgNames {
    return @[
             DEVICE_ID_ARGNAME,
             APP_ID_ARGNAME,
             PROFILE_PATH_ARGNAME,
             CODESIGN_ID_ARGNAME,
             RESIGN_OBJECT_ARGNAME
             ];
}

+ (NSArray<NSString *> *)resourcesFromArgs:(NSDictionary *)args {
    NSString *resourcesPath = args[RESOURCES_PATH_FLAG];
    if (resourcesPath.length) {
        resourcesPath = [FileUtils expandPath:resourcesPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        BOOL isDirectory = NO;
        if (![fileManager fileExistsAtPath:resourcesPath isDirectory:&isDirectory]) {
            ConsoleWriteErr(@"No directory or file at: %@", resourcesPath);
            return @[];
        }
        if (isDirectory) {
            NSMutableArray<NSString *> *resources = [[FileUtils depthFirstPathsStartingAtDirectory:resourcesPath error:nil] mutableCopy];
            // Remove the containing directory from being injected later.
            [resources removeObjectAtIndex:0];
            return [NSArray arrayWithArray:resources];
        } else {
            return @[resourcesPath];
        }
    }
    
    return @[];
}

+ (Device *)deviceFromArgs:(NSDictionary *)args {
    NSString *deviceID = args[DEVICE_ID_FLAG] ?: args[DEVICE_ID_ARGNAME] ?: [DeviceUtils defaultDeviceID];
    return [Device withID:deviceID];
}

+ (Device *)simulatorFromArgs:(NSDictionary *)args {
    NSString *deviceID = args[DEVICE_ID_FLAG] ?: args[DEVICE_ID_ARGNAME] ?: [DeviceUtils defaultSimulatorID];
    
    if (![DeviceUtils isSimulatorID:deviceID]) {
        @throw [NSException exceptionWithName:@"InvalidArgumentException"
                                       reason:@"The specified device id does not match a simulator id"
                                       userInfo:nil];
    }
    
    return [Device withID:deviceID];
}

+ (CodesignIdentity *)codesignIDFromArgs:(NSDictionary *)args {
    NSString *codesignID = args[CODESIGN_ID_FLAG] ?: args[CODESIGN_ID_ARGNAME];
    
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

+ (NSString *)resignObjectFromArgs:(NSDictionary *)args {
    return args[RESIGN_OBJECT_PATH_FLAG] ?: args[RESIGN_OBJECT_ARGNAME];
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

+ (NSArray <NSString *>*)positionalArgShortFlags {
    return @[
             DEVICE_ID_FLAG,
             APP_ID_FLAG,
             PROFILE_PATH_FLAG,
             CODESIGN_ID_FLAG,
             RESIGN_OBJECT_PATH_FLAG
             ];
}

+ (id<iOSDeviceManagementCommand>)command {
    [self validateConformsToProtocol];
    return (id<iOSDeviceManagementCommand>)self;
}

+ (NSString *)usage {
    id <iOSDeviceManagementCommand> cmd = [self command];
    NSMutableString *usage = [NSMutableString string];
    [usage appendFormat:@"\n\t%@", [cmd name]];
    
    for (NSString *argname in self.positionalArgNames) {
        [usage appendFormat:@" <%@>", argname];
    }
    
    [usage appendString:@"\n"];
    
    for (CommandOption *op in [cmd options]) {
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
        if (op != [[cmd options] lastObject]) {
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
