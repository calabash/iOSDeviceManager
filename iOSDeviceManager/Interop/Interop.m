#import "Interop.h"
#import "CLI.h"

#define SUCCESS 0
#define FAILURE 1
#define STR( cString ) [NSString stringWithCString:( cString ) encoding:NSUTF8StringEncoding]

int execute(char *command) {
    @autoreleasepool {
        NSString *commandString = STR(command);
        
        NSArray<NSString *> *args = [commandString componentsSeparatedByString:@" "];
        [CLI process:args];
    }
}
