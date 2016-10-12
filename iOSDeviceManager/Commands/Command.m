
#import "iOSDeviceManagementCommand.h"
#import "Command.h"
#import "CLI.h"

@implementation Command
static NSMutableDictionary <NSString *, NSArray<CommandOption *> *> *classOptionArrayMap;
static NSMutableDictionary <NSString *, NSDictionary<NSString *, CommandOption *> *> *classOptionDictMap;

+ (NSString *)name {
    @throw [NSException exceptionWithName:@"ProgrammerErrorException"
                                   reason:@"+(NSString *)name shoudl be overidden by sublass"
                                 userInfo:@{@"this class" : NSStringFromClass(self.class)}];
}

+ (void)load {
    static dispatch_once_t oncet;
    dispatch_once(&oncet, ^{
        classOptionDictMap = [NSMutableDictionary dictionary];
        classOptionArrayMap = [NSMutableDictionary dictionary];
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
    [usage appendFormat:@"\n\t%@\n", [cmd name]];
    
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
        [usage appendString:@"\n"];
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

+ (NSDictionary<NSString *, NSString *> *)parseArgs:(NSArray <NSString *> *)args
                                           exitCode:(int *)exitCode {
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < args.count; i+=2) {
        CommandOption *op = [self optionForFlag:args[i]];
        if (op == nil) {
            printf("Unrecognized flag: %s\n", [args[i] cStringUsingEncoding:NSUTF8StringEncoding]);
            [self printUsage];
            *exitCode = iOSReturnStatusCodeUnrecognizedFlag;
            return nil;
        }
        if (args.count <= i + 1) {
            printf("No value provided for %s\n", [args[i] cStringUsingEncoding:NSUTF8StringEncoding]);
            [self printUsage];
            *exitCode = iOSReturnStatusCodeMissingArguments;
            return nil;
        }
        values[op.shortFlag] = args[i+1];
    }
    *exitCode = iOSReturnStatusCodeEverythingOkay;
    return values;
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
    if (classOptionArrayMap[self.name] == nil) {
        NSDictionary *commandOptions = [CLI CLIDict][[self name]];
        if (!commandOptions) {
            @throw [NSException exceptionWithName:@"ProgrammerErrorException"
                                           reason:@"CLI.json has no command options for this command, or this command has no name."
                                         userInfo:@{@"name" : [self name] ?: @""}];
        }
        
        NSMutableArray <CommandOption *> *options = [NSMutableArray arrayWithCapacity:commandOptions.count];
        for (NSString *shortFlag in commandOptions) {
            NSDictionary *attrs = commandOptions[shortFlag];
            NSString *longFlag = attrs[@"longFlag"];
            NSString *optionName = attrs[@"optionName"];
            NSString *info = attrs[@"info"];
            BOOL required = [attrs[@"required"] boolValue];
            id def = attrs[@"default"];
            
            CommandOption *opt = [CommandOption withShortFlag:shortFlag
                                                     longFlag:longFlag
                                                   optionName:optionName
                                                         info:info
                                                     required:required
                                                   defaultVal: def];
            [options addObject:opt];
        }
        classOptionArrayMap[self.name] = options;
    }
    return classOptionArrayMap[self.name];
}

@end
