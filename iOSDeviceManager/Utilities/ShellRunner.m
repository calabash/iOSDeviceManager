
#import "ShellRunner.h"
#import "MachClock.h"
#import "ConsoleWriter.h"


@implementation ShellRunner

+ (ShellResult *)command:(NSString *)command
                    args:(NSArray *)args
                 timeout:(NSTimeInterval)timeout {

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:command];
    [task setArguments:args];

    NSPipe *outPipe = [NSPipe pipe];
    [task setStandardOutput:outPipe];

    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardError:errPipe];

    BOOL timedOut = NO;
    NSTimeInterval startTime = [[MachClock sharedClock] absoluteTime];
    NSTimeInterval endTime = startTime + timeout;

    BOOL raised = NO;
    ShellResult *result = nil;

    NSString *execStr;
    NSString *argsStr = [args componentsJoinedByString:@" "];
    execStr = [command stringByAppendingFormat:@" %@", argsStr];

    @try {
        [task launch];

        while ([task isRunning]) {
            if ([[MachClock sharedClock] absoluteTime] > endTime) {
                timedOut = YES;
                [task terminate];
            }
        }
    } @catch (NSException *exception) {
        ConsoleWriteErr(@"Caught an exception trying to execute:\n    %@ %@",
                       execStr);
        ConsoleWriteErr(@"===  EXCEPTION ===");
        ConsoleWriteErr(@"%@", exception);
        ConsoleWriteErr(@"");
        ConsoleWriteErr(@"=== STACK SYMBOLS === ");
        ConsoleWriteErr(@"%@", [exception callStackSymbols]);
        ConsoleWriteErr(@"");
        raised = YES;
    } @finally {
        NSTimeInterval elapsed = [[MachClock sharedClock] absoluteTime] - startTime;
        if (raised) {
            result = [ShellResult withFailedCommand:command elapsed:elapsed];
        } else {
            result = [ShellResult withTask:task elapsed:elapsed didTimeOut:timedOut];
        }
        task = nil;
    }

    if ([self verbose]) {
        [result logStdoutAndStderr];
    }

    return result;
}

+ (ShellResult *)xcrun:(NSArray *)args timeout:(NSTimeInterval)timeout {
    return [ShellRunner command:@"/usr/bin/xcrun" args:args timeout:timeout];
}

+ (BOOL)verbose {
    return [[NSProcessInfo processInfo].environment[@"VERBOSE"] boolValue];
}

@end
