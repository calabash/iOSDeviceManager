
#import "ShellRunner.h"
#import "ShellResult.h"

@implementation ShellRunner

+ (NSArray<NSString *> *)xcrun:(NSArray *)args {
    return [self shell:@"/usr/bin/xcrun" args:args];
}

/*
 http://stackoverflow.com/questions/412562/execute-a-terminal-command-from-a-cocoa-app/696942#696942
 */
+ (NSArray<NSString *> *)shell:(NSString *)cmd args:(NSArray *)args {
    NSMutableString *argString = [cmd mutableCopy];
    for (NSString *arg in args) {
        [argString appendFormat:@" %@", arg];
    }
    if ([self verbose]) {
        NSLog(@"$ %@", argString);
    }
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: cmd];
    [task setArguments: args];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];

    NSFileHandle *file = [pipe fileHandleForReading];

    [task launch];

    [task waitUntilExit];
    if (task.terminationStatus != 0) {
        NSLog(@"Failed to execute command `%@` (Exit Status: %@)",  argString, @(task.terminationStatus));
        return nil;
    }

    NSData *data = [file readDataToEndOfFile];

    NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return [string componentsSeparatedByString:@"\n"];
}

+ (ShellResult *)xcrun:(NSArray *)args timeout:(NSTimeInterval)timeout {
    NSString *xcrun = @"/usr/bin/xcrun";

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:xcrun];
    [task setArguments:args];

    NSPipe *outPipe = [NSPipe pipe];
    [task setStandardOutput:outPipe];

    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardError:errPipe];

    BOOL timedOut = NO;
    NSDate *endDate = [[NSDate date] dateByAddingTimeInterval:timeout];
    NSDate *startDate = [NSDate date];

    BOOL raised = NO;
    ShellResult *result = nil;

    NSString *command = [xcrun stringByAppendingFormat:@" %@",
                         [args componentsJoinedByString:@" "]];
    NSLog(@"EXEC: %@", command);

    @try {
        [task launch];

        while ([task isRunning]) {
            if ([endDate earlierDate:[NSDate date]] == endDate) {
                timedOut = YES;
                [task terminate];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"ERROR: Caught an exception trying to execute:\n    %@ %@",
              xcrun, [args componentsJoinedByString:@" "]);
        NSLog(@"ERROR: ===  EXCEPTION ===");
        NSLog(@"%@", exception);
        NSLog(@"");
        NSLog(@"ERROR: === STACK SYMBOLS === ");
        NSLog(@"%@", [exception callStackSymbols]);
        NSLog(@"");
        raised = YES;
    } @finally {
        NSTimeInterval elapsed = -1.0 * [startDate timeIntervalSinceNow];
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

+ (NSString *)pwd {
    return [[NSFileManager defaultManager] currentDirectoryPath];
}

+ (NSString *)tmpDir {
    return NSTemporaryDirectory();
}

+ (NSString *)which:(NSString *)prog {
    NSArray <NSString *> *results = [self shell:@"/usr/bin/which" args:@[prog ?: @""]];
    return results.count > 0 ? results[0] : nil;
}

+ (BOOL)verbose {
    return [[NSProcessInfo processInfo].environment[@"VERBOSE"] boolValue];
}
@end
