
#import <Foundation/Foundation.h>

@interface ShellRunner : NSObject
+ (NSArray<NSString *> *)shell:(NSString *)cmd args:(NSArray *)args;
@end
