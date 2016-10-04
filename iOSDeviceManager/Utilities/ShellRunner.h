
#import <Foundation/Foundation.h>

@class ShellResult;

@interface ShellRunner : NSObject

typedef void (^block)(void);

+ (NSArray<NSString *> *)shell:(NSString *)cmd args:(NSArray *)args;
+ (void)shellInBackground:(NSString *)cmd args:(NSArray *)args;
+ (NSArray<NSString *> *)xcrun:(NSArray *)args;
+ (ShellResult *)xcrun:(NSArray *)args timeout:(NSTimeInterval)timeout;
+ (NSString *)pwd;
+ (NSString *)tmpDir;
+ (NSString *)which:(NSString *)prog;
+ (BOOL)verbose;

@end
