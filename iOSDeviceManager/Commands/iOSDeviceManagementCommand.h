
#import <Foundation/Foundation.h>
#import "ServerConfig.h"
#import "CommandOption.h"

@protocol iOSDeviceManagementCommand <NSObject>
+ (NSString *)name;
+ (void)printUsage;
+ (CommandOption *)optionForFlag:(NSString *)flag;
+ (iOSReturnStatusCode)execute:(NSDictionary *)args;
+ (NSArray<CommandOption *> *)options;
+ (NSDictionary<NSString *, NSString *> *)parseArgs:(NSArray <NSString *> *)args
                                           exitCode:(int *)exitCode;
@end
