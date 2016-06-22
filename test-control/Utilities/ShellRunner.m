
#import "ShellRunner.h"

@implementation ShellRunner
/*
 http://stackoverflow.com/questions/412562/execute-a-terminal-command-from-a-cocoa-app/696942#696942
 */
+ (NSArray<NSString *> *)shell:(NSString *)cmd args:(NSArray *)args {
    NSLog(@"$ %@ %@", cmd, args);
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: cmd];
    [task setArguments: args];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    
    [task waitUntilExit];
    if (task.terminationStatus != 0) {
        NSLog(@"Failed to execute %@ with args %@ (Exit Status: %@)", cmd, args, @(task.terminationStatus));
        return nil;
    }
    
    NSData *data = [file readDataToEndOfFile];
    
    NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return [string componentsSeparatedByString:@"\n"];
}
@end
