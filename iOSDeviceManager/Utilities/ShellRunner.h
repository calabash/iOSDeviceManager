
#import <Foundation/Foundation.h>

@interface ShellRunner : NSObject
+ (NSArray<NSString *> *)shell:(NSString *)cmd args:(NSArray *)args;
+ (NSArray<NSString *> *)xcrun:(NSArray *)args;
+ (NSString *)pwd;
+ (NSString *)tmpDir;
+ (BOOL)verbose;
@end
