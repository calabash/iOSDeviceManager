
#import <Foundation/Foundation.h>
#import "CommandOption.h"
#import "Device.h"
#import "iOSReturnStatusCode.h"

@protocol iOSDeviceManagementCommand <NSObject>
+ (Device *)deviceFromArgs:(NSDictionary *)args;
+ (NSString *)name;
+ (void)printUsage;
+ (NSArray <NSString *> *)positionalArgNames;
+ (CommandOption *)optionForFlag:(NSString *)flag;
+ (iOSReturnStatusCode)execute:(NSDictionary *)args;
+ (NSArray<CommandOption *> *)options;
+ (NSDictionary <NSString *, CommandOption *> *)optionDict; //keyed on short flag
+ (NSString *)usage;
@end
