
#import <Foundation/Foundation.h>

@class ShellResult;

@interface ShellRunner : NSObject

+ (NSArray<NSString *> *)shell:(NSString *)cmd args:(NSArray *)args;
+ (NSArray<NSString *> *)xcrun:(NSArray *)args;
+ (ShellResult *)xcrun:(NSArray *)args timeout:(NSTimeInterval)timeout;
+ (NSString *)pwd;
+ (NSString *)tmpDir;
+ (BOOL)verbose;

@end
