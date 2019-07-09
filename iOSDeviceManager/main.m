
#import "CLI.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [iOSDeviceManagerLogging startLumberjackLogging];
        return (int)[CLI process:[NSProcessInfo processInfo].arguments];
    }
}
