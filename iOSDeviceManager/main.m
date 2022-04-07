
#import "CLI.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // LOGFIX[iOSDeviceManagerLogging startLumberjackLogging];
        return (int)[CLI process:[NSProcessInfo processInfo].arguments];
    }
}
