
#import "Device.h"
#import "iOSDeviceManagementCommand.h"

@interface Command : NSObject<iOSDeviceManagementCommand>
@end

extern NSString *const HELP_SHORT_FLAG;
extern NSString *const HELP_LONG_FLAG;
extern NSString *const DEVICE_ID_FLAG;
