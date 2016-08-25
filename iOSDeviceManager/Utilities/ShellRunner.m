
#import "ShellRunner.h"

@interface ShellResult ()

- (instancetype)initWithTask:(NSTask *)task
                     elapsed:(NSTimeInterval)elapsed
                  didTimeOut:(BOOL)didTimeOut;

@property(assign) BOOL didTimeOut;
@property(assign) NSTimeInterval timeout;
@property(assign, readonly) NSTimeInterval elapsed;
@property(copy) NSString *command;
@property(assign, readonly) BOOL success;
@property(assign, readonly) NSInteger exitStatus;
@property(copy) NSString *stdoutStr;
@property(copy) NSString *stderrStr;
@property(copy) NSArray<NSString  *> *stdoutLines;

@end

@implementation ShellResult

+ (NSString *)stringFromPipe:(NSPipe *)pipe {
    NSFileHandle *fileHandle = [pipe fileHandleForReading];
    NSData *data = [fileHandle readDataToEndOfFile];
    return [[NSString alloc] initWithData:data
                             encoding:NSUTF8StringEncoding];
}

@synthesize didTimeOut = _didTimeOut;
@synthesize elapsed = _elapsed;
@synthesize command = _command;
@synthesize success = _success;
@synthesize exitStatus = _exitStatus;
@synthesize stdoutStr = _stdoutStr;
@synthesize stderrStr = _stderrStr;
@synthesize stdoutLines = _stdoutLines;

+ (ShellResult *)withTask:(NSTask *)task
                  elapsed:(NSTimeInterval)elapsed
               didTimeOut:(BOOL)didTimeOut {
    return [[ShellResult alloc] initWithTask:task
                                     elapsed:elapsed
                                  didTimeOut:didTimeOut];
}

- (instancetype)initWithTask:(NSTask *)task
                     elapsed:(NSTimeInterval)elapsed
                  didTimeOut:(BOOL)didTimeOut {
     self = [super init];
    if (self) {
        _elapsed = elapsed;
        _command = [NSString stringWithFormat:@"%@ %@",
                             task.launchPath,
                             [task.arguments componentsJoinedByString:@" "]];
        _didTimeOut = didTimeOut;
        if (_didTimeOut) {
            _exitStatus = NSIntegerMin;
            _success = NO;
        } else {
            _exitStatus = task.terminationStatus;
            _success = _exitStatus == 0;
        }

        _stdoutStr = [ShellResult stringFromPipe:task.standardOutput];
        _stderrStr = [ShellResult stringFromPipe:task.standardError];

        _stdoutLines = [_stdoutStr componentsSeparatedByString:@"\n"];
    }
    return self;
}

- (NSString *)stdout { return _stdoutStr; }
- (NSString *)stderr { return _stderrStr; }

- (void)logStdoutAndStderr {
    if (!self.didTimeOut) {

        NSLog(@"EXEC: %@", self.command);

        if (!self.stdoutStr && self.stdoutStr.length != 0) {
            NSLog(@"=== STDOUT ===");
            NSLog(@"%@", self.stdoutStr);
        }

        if (!self.stderrStr && self.stderrStr.length != 0) {
            NSLog(@"=== STDERR ===");
            NSLog(@"%@", self.stderrStr);
        }
    }
}


@end

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

    [task launch];

    while ([task isRunning]) {
        if ([endDate earlierDate:[NSDate date]] == endDate) {
            timedOut = YES;
            [task terminate];
        }
    }

    NSTimeInterval elapsed = -1.0 * [startDate timeIntervalSinceNow];
    ShellResult *result = [ShellResult withTask:task elapsed:elapsed didTimeOut:timedOut];

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

+ (BOOL)verbose {
    return [[NSProcessInfo processInfo].environment[@"VERBOSE"] boolValue];
}
@end
