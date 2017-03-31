
#import <Foundation/Foundation.h>

@interface ExceptionUtils : NSObject
+ (void)throwWithName:(NSString *)name format:(NSString *)fmt, ...;
#define THROW(name, fmt, ...) [ExceptionUtils throwWithName:(name) format:fmt, ##__VA_ARGS__ ]
#define CBXThrowExceptionIf(condition, fmt, ...) if (! (condition) ) { THROW(@"CBXException", fmt, ##__VA_ARGS__); }
@end
