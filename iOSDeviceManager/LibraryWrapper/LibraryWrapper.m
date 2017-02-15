#import "LibraryWrapper.h"

#define STR( cString ) [NSString stringWithCString:( cString ) encoding:NSUTF8StringEncoding]

int execute(char *command) {
    @autoreleasepool {
        NSString *commandString = STR(command);
        NSArray<NSString *> *args = [commandString componentsSeparatedByString:@" "];
        
        return [CLI process:args];
    }
}
