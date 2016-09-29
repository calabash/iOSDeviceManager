#import "CLIShim.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        return [CLIShim process:[NSProcessInfo processInfo].arguments];
    }
    return 0;
}
