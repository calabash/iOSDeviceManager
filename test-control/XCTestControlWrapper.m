
#import "XCTestControlWrapper.h"
#import "DeviceTestParameters.h"
#import "TestControlArgParser.h"
#import "Device.h"

void start_test(int argc, const char *argv[]) {
    @autoreleasepool {
        NSMutableArray<NSString *>*args = [NSMutableArray arrayWithCapacity:argc];
        for (int i = 0; i < argc; i++) {
            [args addObject:[[NSString alloc] initWithCString:argv[i] encoding:NSUTF8StringEncoding]];
        }
    
        NSDictionary *parsedArgs = [TestControlArgParser parseArgs:args];
        TestParameters *params = [TestParameters fromJSON:parsedArgs];
        
        if (![Device startTest:params]) {
            exit(1);
        }
    }
}
