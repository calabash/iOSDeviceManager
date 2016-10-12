
#import "ConsoleWriter.h"

@implementation ConsoleWriter
+ (void)write:(NSString *)fmt, ... {
    va_list args;
    va_start(args, fmt);
    NSString *output = [[NSString alloc] initWithFormat:fmt arguments:args];
    fprintf(stdout, "%s", [output cStringUsingEncoding:NSUTF8StringEncoding]);
    va_end(args);
}
@end
