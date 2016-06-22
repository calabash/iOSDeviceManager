
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

int install_app(const char *czPathToBundle, const char *czDeviceID, const char *czCodesignID) {
    NSString *pathToBundle = [NSString stringWithCString:czPathToBundle encoding:NSUTF8StringEncoding];
    NSString *deviceID = [NSString stringWithCString:czDeviceID encoding:NSUTF8StringEncoding];
    NSString *codesignID = [NSString stringWithCString:czCodesignID encoding:NSUTF8StringEncoding];
    
    BOOL success = [Device installApp:pathToBundle deviceID:deviceID codesignID:codesignID];
    return success ? 0 : 1;
}
