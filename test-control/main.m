
#import "DeviceTestParameters.h"
#import "TestControlArgParser.h"
#import "Device.h"

#import "XCTestControlWrapper.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
//        install_app("/Users/chrisf/calabash-xcuitest-server/Products/ipa/UnitTestApp/UnitTestApp.app",
//                    "49a29c9e61998623e7909e35e8bae50dd07ef85f",
//                    "iPhone Developer: Chris Fuentes (G7R46E5NX7)");
        
        int ret = install_app("/Users/chrisf/calabash-xcuitest-server/Products/app/UnitTestApp/UnitTestApp.app",
                    "BFDFE518-E33E-407A-9EE8-A745CAA87099",
                    "");
        return ret;
        
        NSArray <NSString *> *args = [NSProcessInfo processInfo].arguments;
        NSDictionary *parsedArgs = [TestControlArgParser parseArgs:args];
        TestParameters *params = [TestParameters fromJSON:parsedArgs];
        
        if (![Device startTest:params]) {
            exit(1);
        }
    }
    return 0;
}
