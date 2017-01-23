
#import "Device.h"
#import "iOSDeviceManagementCommand.h"

@interface Command : NSObject<iOSDeviceManagementCommand>
@end

extern const NSString *DEVICE_ID_ARGNAME;
extern const NSString *DEVICE_ID_FLAG;
extern const NSString *DEFAULT_DEVICE_ID_KEY;
extern const NSString *DEFAULT_SIMULATOR_ID_KEY;
