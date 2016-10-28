
#import "ShellResult.h"
#import "ConsoleWriter.h"
#import "CocoaLumberjack.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

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
        ConsoleWriteErr(@"Caught an exception when reading the %@ of command:\n    %@",
              isStdOut ? @"stdout" : @"stderr", command);
        ConsoleWriteErr(@"===  EXCEPTION ===");
        ConsoleWriteErr(@"%@", exception);
        ConsoleWriteErr(@"");
        ConsoleWriteErr(@"=== STACK SYMBOLS === ");
        ConsoleWriteErr(@"%@", [exception callStackSymbols]);
        ConsoleWriteErr(@"");
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
        DDLogInfo(@"EXEC: %@", self.command);

        if (self.stdoutStr && self.stdoutStr.length != 0) {
            DDLogInfo(@"=== STDOUT ===");
            DDLogInfo(@"%@", self.stdoutStr);
        }

        if (self.stderrStr && self.stderrStr.length != 0) {
            ConsoleWriteErr(@"=== STDERR ===");
            ConsoleWriteErr(@"%@", self.stderrStr);
        }
    }
}

@end
