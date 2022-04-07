
#import "ConsoleWriter.h"

//LOGFIXstatic const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation ConsoleWriter
+ (void)write:(NSString *)fmt, ... {
    va_list args;
    va_start(args, fmt);
    NSString *output = [[NSString alloc] initWithFormat:fmt arguments:args];
    fprintf(stdout, "%s\n", [output cStringUsingEncoding:NSUTF8StringEncoding]);
    fflush(stdout);
//LOGFIX    DDLogVerbose(@"CONSOLE: %@", output);
    va_end(args);
}

+ (void)logInfo:(NSString *)fmt, ... {
    va_list args;
    va_start(args, fmt);
    NSString *output = [[NSString alloc] initWithFormat:fmt arguments:args];
//LOGFIX    DDLogInfo(@"%@", output);
    va_end(args);
}

+ (void)err:(NSString *)fmt, ... {
    va_list args;
    va_start(args, fmt);
    NSString *output = [[NSString alloc] initWithFormat:fmt arguments:args];
    fprintf(stderr, "%s\n", [output cStringUsingEncoding:NSUTF8StringEncoding]);
    fflush(stderr);
//LOGFIX    DDLogError(@"%@", output);
    va_end(args);
}
@end
