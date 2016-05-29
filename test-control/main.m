
#import "DeviceTestParameters.h"
#import "TestControlArgParser.h"
#import "Device.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSArray <NSString *> *args = [NSProcessInfo processInfo].arguments;
        NSDictionary *parsedArgs = [TestControlArgParser parseArgs:args];
        TestParameters *params = [TestParameters fromJSON:parsedArgs];
        
        if (![Device startTest:params]) {
            exit(1);
        }
    }
    return 0;
}
