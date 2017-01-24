
#import "Device.h"
#import "iOSDeviceManagementCommand.h"

@interface Command : NSObject<iOSDeviceManagementCommand>
@end

extern NSString *const DEVICE_ID_FLAG;
extern NSString *const DEFAULT_DEVICE_ID_KEY;
extern NSString *const DEFAULT_SIMULATOR_ID_KEY;
