
#import "SimulateLocationCommand.h"
static NSString *const DEVICE_ID_FLAG = @"-d";
static NSString *const LOCATION_FLAG = @"-l";

@implementation SimulateLocationCommand
+ (NSString *)name {
    return @"set_location";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    NSString *ll = args[LOCATION_FLAG];
    NSArray *latlng = [ll componentsSeparatedByString:@","];
    if (latlng.count != 2) {
        ConsoleWriteErr(@"Expected lat,lng: Got %@", ll);
        return iOSReturnStatusCodeInvalidArguments;
    }
    return [Device setLocation:args[DEVICE_ID_FLAG]
                           lat:[latlng[0] doubleValue]
                           lng:[latlng[1] doubleValue]];
}
@end
