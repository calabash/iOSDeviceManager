
#import "Device.h"
#import "iOSDeviceManagementCommand.h"

@interface Command : NSObject<iOSDeviceManagementCommand>
@end

static NSString *const BUNDLE_ID_FLAG = @"-b";
static NSString *const APP_PATH_FLAG = @"-a";
static NSString *const DEVICE_ID_FLAG = @"-d";
static NSString *const SESSION_ID_FLAG = @"-s";
static NSString *const KEEP_ALIVE_FLAG = @"-k";
static NSString *const CODESIGN_IDENTITY_FLAG = @"-c";
static NSString *const UPDATE_APP_FLAG = @"-u";
static NSString *const LOCATION_FLAG = @"-l";
static NSString *const FILEPATH_FLAG = @"-f";
static NSString *const OVERWRITE_FLAG = @"-o";
