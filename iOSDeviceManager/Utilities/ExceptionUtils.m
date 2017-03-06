
#import "ExceptionUtils.h"

@implementation ExceptionUtils
+ (void)throwWithName:(NSString *)name format:(NSString *)fmt, ... {
    va_list args;
    va_start(args, fmt);
    NSString *reason = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);

    @throw [NSException exceptionWithName:name
                                   reason:reason
                                 userInfo:nil];
}
@end
