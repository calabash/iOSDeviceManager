
#import "iOSDeviceManagementCommand.h"
#import "Command.h"
#import "CLI.h"
#import "ConsoleWriter.h"
#import "DeviceUtils.h"

const NSString *DEVICE_ID_ARGNAME = @"device_id";
const NSString *DEVICE_ID_FLAG = @"-d";
const NSString *DEFAULT_DEVICE_ID_KEY = @"default_device_id";
const NSString *DEFAULT_SIMULATOR_ID_KEY = @"default_simulator_id";

@implementation Command
static NSMutableDictionary <NSString *, NSDictionary<NSString *, CommandOption *> *> *classOptionDictMap;

+ (Device *)deviceFromArgs:(NSDictionary *)args {
    NSString *deviceID = args[DEVICE_ID_FLAG] ?: args[DEVICE_ID_ARGNAME] ?: args[DEFAULT_DEVICE_ID_KEY];
    return [Device withID:deviceID];
}

+ (Device *)simulatorFromArgs:(NSDictionary *)args {
    NSString *deviceID = args[DEVICE_ID_FLAG] ?: args[DEVICE_ID_ARGNAME] ?: args[DEFAULT_SIMULATOR_ID_KEY];
    
    if (![DeviceUtils isSimulatorID:deviceID]) {
        @throw [NSException exceptionWithName:@"InvalidArgumentException"
                                       reason:@"The specified device id does not match a simulator id"
                                       userInfo:nil];
    }
    
    return [Device withID:deviceID];
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

+ (NSArray <NSString *>*)positionalArgNames {
    return @[
             DEVICE_ID_ARGNAME
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
