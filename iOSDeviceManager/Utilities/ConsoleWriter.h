
#import <Foundation/Foundation.h>

@interface ConsoleWriter : NSObject
+ (void)write:(NSString *)fmt, ...;
+ (void)err:(NSString *)fmt, ...;

#define ConsoleWriteErr(fmt, ...) [ConsoleWriter err:fmt,  ##__VA_ARGS__ ]
@end
