
#import "Device.h"
#import "iOSDeviceManagementCommand.h"

@interface Command : NSObject
+ (NSString *)name;
+ (NSArray <CommandOption *> *)options;
+ (NSDictionary <NSString *, CommandOption *> *)optionDict; //keyed on short flag
+ (NSString *)usage;
+ (void)printUsage;
+ (CommandOption *)optionForFlag:(NSString *)flag;
+ (NSDictionary<NSString *, NSString *> *)parseArgs:(NSArray <NSString *> *)args
                                           exitCode:(int *)exitCode;
@end
