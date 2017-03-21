
#import "Device.h"
#import "iOSDeviceManagementCommand.h"

@interface Command : NSObject<iOSDeviceManagementCommand>
@end

extern NSString *const HELP_SHORT_FLAG;
extern NSString *const HELP_LONG_FLAG;
extern NSString *const DEVICE_ID_FLAG;
extern NSString *const BUNDLE_ID_OPTION_NAME;
extern NSString *const DEVICE_ID_OPTION_NAME;
extern NSString *const CODESIGN_ID_OPTION_NAME;
extern NSString *const RESOURCES_PATH_OPTION_NAME;
