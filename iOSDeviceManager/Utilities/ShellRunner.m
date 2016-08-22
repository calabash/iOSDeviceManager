
#import "ShellRunner.h"

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

+ (NSDictionary *)xcrun:(NSArray *)args timeout:(NSTimeInterval)timeout {
    NSString *xcrun = @"/usr/bin/xcrun";

    NSString *cmd = [NSString stringWithFormat:@"%@ %@", xcrun,
                     [args componentsJoinedByString:@" "]];

    if ([self verbose]) {
        NSLog(@"EXEC: %@", cmd);
    }

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:xcrun];
    [task setArguments:args];

    NSPipe *outPipe = [NSPipe pipe];
    [task setStandardOutput:outPipe];
    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardError:errPipe];

    NSFileHandle *outFile = [outPipe fileHandleForReading];
    NSFileHandle *errFile = [errPipe fileHandleForReading];

    NSDate *endDate = [[NSDate date] dateByAddingTimeInterval:timeout];
    BOOL timedOut = NO;

    NSDate *start = [NSDate date];
    [task launch];

    while ([task isRunning]) {
        if ([endDate earlierDate:[NSDate date]] == endDate) {
            timedOut = YES;
            [task terminate];
        }
    }

    NSTimeInterval elapsed = [start timeIntervalSinceNow];

    NSMutableDictionary *result = [@{} mutableCopy];
    result[@"cmd"] = cmd;

    if (timedOut) {
        NSLog(@"Command timed out after %@ seconds", @(elapsed));
        result[@"timedOut"] = @(YES);
    } else {
        result[@"success"] = @(task.terminationStatus == 0 ? YES : NO);
        result[@"exitStatus"] = @(task.terminationStatus);
        NSData *data = [outFile readDataToEndOfFile];
        NSString *string= [[NSString alloc] initWithData:data
                                                encoding: NSUTF8StringEncoding];
        result[@"out"] = [string componentsSeparatedByString:@"\n"];

        data = [errFile readDataToEndOfFile];
        string= [[NSString alloc] initWithData:data
                                      encoding: NSUTF8StringEncoding];
        result[@"err"] = [string componentsSeparatedByString:@"\n"];
    }
    return result;
}

+ (NSString *)pwd {
    return [[NSFileManager defaultManager] currentDirectoryPath];
}

+ (NSString *)tmpDir {
    return NSTemporaryDirectory();
}

+ (BOOL)verbose {
    return [[NSProcessInfo processInfo].environment[@"VERBOSE"] boolValue];
}
@end
