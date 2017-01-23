
#import "iOSDeviceManagementCommand.h"
#import <objc/runtime.h>
#import "ShellRunner.h"
#import "Command.h"
#import "CLI.h"
#import "ConsoleWriter.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation CLI
static NSMutableDictionary <NSString *, Class> *commandClasses;

+ (void)load {
    unsigned int outCount;
    Class *classes = objc_copyClassList(&outCount);
    commandClasses = [NSMutableDictionary dictionaryWithCapacity:outCount];
    for (int i = 0; i < outCount; i++) {
        Class c = classes[i];
        if (class_conformsToProtocol(c, @protocol(iOSDeviceManagementCommand))) {
            if (![c isSubclassOfClass:[Command class]]) {
                @throw [NSException exceptionWithName:@"ProgrammerErrorException"
                                               reason:@"Commands should subclass the Command class"
                                             userInfo:nil];
            }
            if ([c class] == [Command class]) {
                continue;
            }
            if ([c name]) {
                commandClasses[[c name]] = c;
            }
        }
    }
    free(classes);
}

+ (void)printUsage {
    printf("USAGE: %s [command] [flags]\n",
           [[[NSProcessInfo processInfo].arguments[0] lastPathComponent]
                cStringUsingEncoding:NSUTF8StringEncoding]);
    for (Class<iOSDeviceManagementCommand> c in [commandClasses allValues]) {
        [c printUsage];
    }
    printf("\n");
}

/*
 For parsing args - positional values may be used (regardless of order) and their
 corresponding property is determined by `positionalArgShortFlag`. Using redundant 
 args will result in iOSReturnStatusCodeInvalidArguments response.
*/
+ (NSDictionary<NSString *, NSString *> *)parseArgs:(NSArray <NSString *> *)args
                                         forCommand:(Class <iOSDeviceManagementCommand>)command
                                           exitCode:(int *)exitCode {
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *possiblePositionalArgShortFlags = [NSMutableArray arrayWithArray:[command positionalArgShortFlags]];
    
    for (int i = 0; i < args.count; i++) {
        CommandOption *op = [command optionForFlag:args[i]];
        if (op == nil) { // This is true when the arg provided isn't a recognized flag or isn't a flag
            if ([possiblePositionalArgShortFlags count] == 0) {
                ConsoleWriteErr(@"Unrecognized flag or unsupported argument: %s\n",
                       [args[i] cStringUsingEncoding:NSUTF8StringEncoding]);
                [self printUsage];
                *exitCode = iOSReturnStatusCodeUnrecognizedFlag;
                return nil;
            } else if ([[args[i] substringToIndex:1] isEqualToString:@"-"]) {
                *exitCode = iOSReturnStatusCodeUnrecognizedFlag;
                return nil;
            } else {
                NSString *positionalArgShortFlag = [command positionalArgShortFlag:args[i]];
                if (positionalArgShortFlag) {
                    // Check if redundant positional args specified
                    if (![possiblePositionalArgShortFlags containsObject:positionalArgShortFlag]) {
                        ConsoleWriteErr(@"Multiple arguments detected for %@", positionalArgShortFlag);
                        [self printUsage];
                        *exitCode = iOSReturnStatusCodeInvalidArguments;
                        return nil;
                    }
                    values[positionalArgShortFlag] = args[i];
                    [possiblePositionalArgShortFlags removeObject:positionalArgShortFlag];
                } else{
                    ConsoleWriteErr(@"Unrecognized flag or unsupported argument: %@\n",
                           [args[i] cStringUsingEncoding:NSUTF8StringEncoding]);
                    [self printUsage];
                    *exitCode = iOSReturnStatusCodeUnrecognizedFlag;
                    return nil;

                }
                continue;
            }
        }
        if (args.count <= i + 1) {
            ConsoleWriteErr(@"No value provided for %@\n", [args[i] cStringUsingEncoding:NSUTF8StringEncoding]);
            [command printUsage];
            *exitCode = iOSReturnStatusCodeMissingArguments;
            return nil;
        }
        if ([values objectForKey:op.shortFlag]) {
            ConsoleWriteErr(@"Multiple arguments detected for %@", op.longFlag);
            [command printUsage];
            *exitCode = iOSReturnStatusCodeInvalidArguments;
            return nil;
        }
        if (op.requiresArgument) {
            values[op.shortFlag] = args[i+1];
            i++;
        } else {
            values[op.shortFlag] = @YES;
        }
    }
    values[DEFAULT_DEVICE_ID_KEY] = [Device defaultDeviceID];
    *exitCode = iOSReturnStatusCodeEverythingOkay;
    return values;
}

+ (iOSReturnStatusCode)process:(NSArray<NSString *> *)args {
    if (args.count <= 1) {
        [self printUsage];
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        NSString *commandName = [args[1] lowercaseString];
        Class <iOSDeviceManagementCommand> command = commandClasses[commandName];
        
        if (command) {
            //Ensure args can be parsed correctly
            NSArray *cmdArgs = args.count == 2 ? @[] : [args subarrayWithRange:NSMakeRange(2, args.count - 2)];
            int ec;
            NSDictionary *parsedArgs = [self parseArgs:cmdArgs
                                            forCommand:command
                                              exitCode:&ec];
            if (ec != iOSReturnStatusCodeEverythingOkay) {
                return ec;
            }

            //Ensure all required args are present
            for (CommandOption *opt in [command options]) {
                if (opt.required && ![parsedArgs.allKeys containsObject:opt.shortFlag]) {
                    printf("Missing required argument '%s'. Use the '%s' flag.\n",
                           [opt.optionName cStringUsingEncoding:NSUTF8StringEncoding],
                           [opt.shortFlag cStringUsingEncoding:NSUTF8StringEncoding]);
                    [command printUsage];
                    return iOSReturnStatusCodeMissingArguments;
                }
            }
            
            //If exit non-0, print usage.
            iOSReturnStatusCode ret = [command execute:parsedArgs];

            DDLogVerbose(@"%@ ==> %d %@", [command name], ret, parsedArgs);

            if (ret != iOSReturnStatusCodeEverythingOkay &&
                ret != iOSReturnStatusCodeFalse) {
                [command printUsage];
            }
            return ret;
        } else {
            [ConsoleWriter err:@"Unrecognized command: %@", commandName];
            [self printUsage];
            return iOSReturnStatusCodeUnrecognizedCommand;
        }
    }
}

@end
