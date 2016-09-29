
#import "CLIShim.h"
#import "ServerConfig.h"
#import "ShellRunner.h"

@implementation CLIShim
+ (iOSReturnStatusCode)process:(NSArray <NSString *> *)args {
    NSString *baseURL = [NSString stringWithFormat:@"http://localhost:%@", @(SERVER_PORT)];
    NSString *healthURL = [NSString stringWithFormat:@"%@/health", baseURL];
    NSString *cliURL = [NSString stringWithFormat:@"%@/cli", baseURL];
    
    //If the server isn't running, try to start it.
    NSDictionary *response = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:healthURL]];
    if (response == nil) {
        if ([ShellRunner which:@"iOSDeviceManagerServer"] == nil) {
            NSLog(@"!!! iOSDeviceManagerServer is not installed !!!");
            return iOSReturnStatusCodeGenericFailure;
        }
        [ShellRunner shell:@"iOSDeviceManagerServer" args:@[@"&"]];
    }
    
    //Pass args to the server
    NSString *argsString = [args componentsJoinedByString:@" "];
    argsString = [NSString stringWithFormat:@"[%@]", argsString];
    NSArray *lines = [ShellRunner shell:@"/usr/bin/curl" args:@[@"-X", @"POST", @"-d", argsString, cliURL]];
    if (lines.count > 0) {
        return [lines[0] intValue];
    }
    return iOSReturnStatusCodeGenericFailure;
}
@end
