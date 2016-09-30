
#import "CLIShim.h"
#import "ServerConfig.h"
#import "ShellRunner.h"

@implementation CLIShim
+ (iOSReturnStatusCode)process:(NSArray <NSString *> *)args {
    NSString *baseURL = [NSString stringWithFormat:@"http://localhost:%@", @(SERVER_PORT)];
    NSString *healthURL = [NSString stringWithFormat:@"%@/health", baseURL];
    NSString *cliURL = [NSString stringWithFormat:@"%@/cli", baseURL];
    
    NSString *$PATH = [NSProcessInfo processInfo].environment[@"PATH"];
    $PATH = [NSString stringWithFormat:@"%@:/usr/local/bin/iOSDeviceManager/bin", $PATH];
    setenv("PATH", [$PATH cStringUsingEncoding:NSUTF8StringEncoding], 1);
    setenv("VERBOSE", "YES", 1);
    
    //If the server isn't running, try to start it.
    NSArray *response = [ShellRunner shell:@"/usr/bin/curl" args:@[healthURL]];
    if (response == nil) {
        NSString *serverPath = [ShellRunner which:@"iOSDeviceManagerServer"];
        if (serverPath == nil) {
            NSLog(@"!!! iOSDeviceManagerServer is not installed !!!");
            return iOSReturnStatusCodeGenericFailure;
        }
        [ShellRunner shellInBackground:serverPath args:@[@"&"]];
        sleep(3); //takes a bit to start the server
        
        response = [ShellRunner shell:@"/usr/bin/curl" args:@[healthURL]];
        if (response == nil) {
            NSLog(@"Server is still not running, exiting...");
            return iOSReturnStatusCodeGenericFailure;
        }
    } else {
        NSLog(@"iOSDeviceManagerServer is running. Status: %@", response);
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
