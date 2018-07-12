
#import "SimulateLocationCommand.h"
#import "ConsoleWriter.h"

static NSString *const LOCATION_OPTION_NAME = @"latitude,longitude";

@implementation SimulateLocationCommand
+ (NSString *)name {
    return @"set-location";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    NSString *ll = args[LOCATION_OPTION_NAME];
    NSArray *latlng = [ll componentsSeparatedByString:@","];
    if (latlng.count != 2) {
        ConsoleWriteErr(@"Expected lat,lng: Got %@", ll);
        return iOSReturnStatusCodeInvalidArguments;
    }
    
    Device *device = [self deviceFromArgs:args];
    if (!device) {
        return iOSReturnStatusCodeDeviceNotFound;
    }
    
    return [device simulateLocationWithLat:[latlng[0] doubleValue] lng:[latlng[1] doubleValue]];
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withPosition:0
                                            optionName:LOCATION_OPTION_NAME
                                                  info:@"latitude and longitude separated by a single comma"
                                              required:YES
                                            defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:DEVICE_ID_OPTION_NAME
                                                   info:@"iOS Simulator GUID, 40-digit physical device ID, or an alias"
                                               required:YES
                                             defaultVal:nil]];
    });
    return options;
}
@end
