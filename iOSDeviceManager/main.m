
#import "CLI.h"
#import "IDMLogger.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [IDMLogger startLumberjackLogging];
        return (int)[CLI process:[NSProcessInfo processInfo].arguments];
    }
}
