
#import "iOSDeviceManagementCommand.h"
#import <objc/runtime.h>
#import "ShellRunner.h"
#import "Command.h"
#import "CLI.h"

@implementation CLI
static NSMutableDictionary <NSString *, Class> *commandClasses;
static NSDictionary *CLIDict;

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
            if ([c name]) {
                commandClasses[[c name]] = c;
            }
        }
    }
    free(classes);
    
    //Load the CLI.json command line options
    NSString *cliJSONPath = [self pathToCLIJSON];
    if (!cliJSONPath || [cliJSONPath isEqualToString:@""]) {
        @throw [NSException exceptionWithName:@"CLI.json error"
                                       reason:@"CLI.json not found."
                                     userInfo:@{@"resource path" : [[NSBundle mainBundle] resourcePath] ?: @""}];
    }
    
    NSData *jsonData = [NSData dataWithContentsOfFile:cliJSONPath];
    NSError *e;
    CLIDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&e];
    if (!CLIDict) {
        @throw [NSException exceptionWithName:@"CLI.json error"
                                       reason:@"CLI.json not parseable."
                                     userInfo:@{@"inner error" : e ?: @""}];
    }
}

+ (NSString *)pathToCLIJSON {
    return [[NSBundle mainBundle] pathForResource:@"CLI" ofType:@"json"];
}

+ (NSDictionary *)CLIDict {
    return CLIDict;
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
            NSDictionary *parsedArgs = [command parseArgs:cmdArgs exitCode:&ec];
            if (ec != iOSReturnStatusCodeEverythingOkay) {
                return ec;
            }
            
            //If no args present and none required, just print usage and exit.
            NSInteger numRequiredArgs = [[command options] filteredArrayUsingPredicate:
                                   [NSPredicate predicateWithFormat:@"SELF.required == YES"]].count;
            if (cmdArgs.count == 0 && numRequiredArgs == 0) {
                [command printUsage];
                return iOSReturnStatusCodeEverythingOkay;
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
