
#import <Foundation/Foundation.h>

@interface ShellResult : NSObject

+ (ShellResult *)withTask:(NSTask *) task
                  elapsed:(NSTimeInterval)elapsed
               didTimeOut:(BOOL)didTimeout;

- (BOOL)didTimeOut;
- (NSTimeInterval)elapsed;
- (NSString *)command;
- (BOOL)success;
- (NSInteger)exitStatus;
- (NSString *)stdoutStr;
- (NSString *)stderrStr;
- (NSArray<NSString *> *)stdoutLines;
- (void)logStdoutAndStderr;

@end

@interface ShellRunner : NSObject

+ (NSArray<NSString *> *)shell:(NSString *)cmd args:(NSArray *)args;
+ (NSArray<NSString *> *)xcrun:(NSArray *)args;
+ (ShellResult *)xcrun:(NSArray *)args timeout:(NSTimeInterval)timeout;
+ (NSString *)pwd;
+ (NSString *)tmpDir;
+ (BOOL)verbose;

@end
