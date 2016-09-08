
#import "ShellRunner.h"

@interface ShellResult ()

- (instancetype)initWithTask:(NSTask *)task
                     elapsed:(NSTimeInterval)elapsed
                  didTimeOut:(BOOL)didTimeOut;

- (instancetype)initWithFailedCommand:(NSString *)command
                              elapsed:(NSTimeInterval)elapsed;


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

+ (NSString *)stringFromPipe:(NSPipe *)pipe
                     command:(NSString *)command
                    isStdOut:(BOOL)isStdOut {
    NSFileHandle *fileHandle = [pipe fileHandleForReading];

    NSString *string = nil;
    @try {
        NSData *data = [fileHandle readDataToEndOfFile];
        string =  [[NSString alloc] initWithData:data
                                        encoding:NSUTF8StringEncoding];
    } @catch (NSException *exception) {
        NSLog(@"ERROR: Caught an exception when reading the %@ of command:\n    %@",
              isStdOut ? @"stdout" : @"stderr", command);
        NSLog(@"ERROR: ===  EXCEPTION ===");
        NSLog(@"%@", exception);
        NSLog(@"");
        NSLog(@"ERROR: === STACK SYMBOLS === ");
        NSLog(@"%@", [exception callStackSymbols]);
        NSLog(@"");
    } @finally {
        [fileHandle closeFile];
    }
    return string;
}

@synthesize didTimeOut = _didTimeOut;
@synthesize elapsed = _elapsed;
@synthesize command = _command;
@synthesize success = _success;
@synthesize exitStatus = _exitStatus;
@synthesize stdoutStr = _stdoutStr;
@synthesize stderrStr = _stderrStr;
@synthesize stdoutLines = _stdoutLines;

+ (ShellResult *)withFailedCommand:(NSString *)command
                           elapsed:(NSTimeInterval)elapsed {
    return [[ShellResult alloc] initWithFailedCommand:command elapsed:elapsed];
}

- (instancetype)initWithFailedCommand:(NSString *)command
                              elapsed:(NSTimeInterval)elapsed {
    self = [super init];
    if (self) {
        _elapsed = elapsed;
        _command = command;
        _success = NO;
        _didTimeOut = NO;
        _exitStatus = NSIntegerMin;
        _stdoutStr = nil;
        _stderrStr = nil;
        _stdoutLines = nil;
    }
    return self;
}

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

        _stdoutStr = [ShellResult stringFromPipe:task.standardOutput
                                         command:_command
                                         isStdOut:YES];
        _stderrStr = [ShellResult stringFromPipe:task.standardError
                                         command:_command
                                         isStdOut:NO];

        _stdoutLines = [_stdoutStr componentsSeparatedByString:@"\n"];
    }
    return self;
}

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

    BOOL raised = NO;
    ShellResult *result = nil;

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
            NSString *command = [xcrun stringByAppendingFormat:@" %@",
                                 [args componentsJoinedByString:@" "]];
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

+ (BOOL)verbose {
    return [[NSProcessInfo processInfo].environment[@"VERBOSE"] boolValue];
}
@end
