
#import "Device.h"
#import "iOSDeviceManagementCommand.h"

@interface Command : NSObject
+ (NSString *)usage;
+ (void)printUsage;
+ (CommandOption *)optionForFlag:(NSString *)flag;
+ (NSDictionary<NSString *, NSString *> *)parseArgs:(NSArray <NSString *> *)args
                                           exitCode:(int *)exitCode;
@end
