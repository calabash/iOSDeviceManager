
#import "CLI.h"
#import <FBControlCore/CalabashUtils.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [iOSDeviceManagerLogging startLumberjackLogging];
        return [iOSDeviceManagerServer start];
    }
}
