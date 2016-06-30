
#import "iOSDeviceManagementCommand.h"
#import "Command.h"

@implementation Command
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
        if (op.additionalInfo && ![op.additionalInfo isEqualToString:@""]) {
            [usage appendFormat:@"\t%@\n", op.additionalInfo];
        }
    }
    return usage;
}

+ (void)printUsage {
    printf("%s", [[self usage] cStringUsingEncoding:NSUTF8StringEncoding]);
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
@end
