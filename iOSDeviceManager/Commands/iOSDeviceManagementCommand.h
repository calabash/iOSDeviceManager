
#import <Foundation/Foundation.h>
#import "CommandOption.h"
#import "Device.h"
#import "iOSReturnStatusCode.h"

@protocol iOSDeviceManagementCommand <NSObject>
+ (NSString *)positionalArgShortFlag:(NSString *)arg;
+ (Device *)deviceFromArgs:(NSDictionary *)args;
+ (NSString *)name;
+ (void)printUsage;
+ (NSArray <NSString *> *)positionalArgShortFlags;
+ (CommandOption *)optionForFlag:(NSString *)flag;
+ (iOSReturnStatusCode)execute:(NSDictionary *)args;
+ (NSArray<CommandOption *> *)options;
+ (NSDictionary <NSString *, CommandOption *> *)optionDict; //keyed on short flag
+ (NSString *)usage;
@end
