
#import "iOSDeviceManagementCommand.h"
#import <objc/runtime.h>
#import "Command.h"
#import "CLI.h"

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
            if ([c name]) {
                commandClasses[[c name]] = c;
            }
        }
    }
    free(classes);
}

+ (void)printUsage {
    printf("USAGE: %s [command] [flags]\n",
           [[NSProcessInfo processInfo].arguments[0] cStringUsingEncoding:NSUTF8StringEncoding]);
    for (Class<iOSDeviceManagementCommand> c in [commandClasses allValues]) {
        [c printUsage];
    }
    printf("\n");
}

+ (iOSReturnStatusCode)process {
    NSArray<NSString *> *args = [NSProcessInfo processInfo].arguments;
    if (args.count <= 1) {
        [self printUsage];
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        NSString *commandName = [args[1] lowercaseString];
        Class <iOSDeviceManagementCommand> command = commandClasses[commandName];
        if (command) {
            //Ensure args can be parsed correctly
            NSArray *cmdArgs = [args subarrayWithRange:NSMakeRange(2, args.count)];
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
                    NSLog(@"Missing required argument '%@'. Use the '%@' flag.", opt.optionName, opt.shortFlag);
                    [command printUsage];
                    return iOSReturnStatusCodeMissingArguments;
                }
            }
            
            //If exit non-0, print usage.
            iOSReturnStatusCode ret = [command execute:parsedArgs];
            if (ret != iOSReturnStatusCodeEverythingOkay) {
                [command printUsage];
            }
            return ret;
        } else {
            NSLog(@"Unrecognized command: %@", commandName);
            return iOSReturnStatusCodeUnrecognizedCommand;
        }
    }
}
@end
