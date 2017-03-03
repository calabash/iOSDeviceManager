
#import <Foundation/Foundation.h>
#import "CommandOption.h"
#import "Device.h"
#import "iOSReturnStatusCode.h"

@protocol iOSDeviceManagementCommand <NSObject>
+ (NSString *)positionalArgShortFlag:(NSString *)arg;
+ (NSArray<NSString *> *)resourcesFromArgs:(NSDictionary *)args;
+ (Device *)deviceFromArgs:(NSDictionary *)args;
+ (Device *)simulatorFromArgs:(NSDictionary *)args;
+ (CodesignIdentity *)codesignIDFromArgs:(NSDictionary *)args;
+ (NSString *)resignObjectFromArgs:(NSDictionary *)args;
+ (NSString *)name;
+ (void)printUsage;
+ (NSArray <NSString *> *)positionalArgShortFlags;
+ (CommandOption *)optionForFlag:(NSString *)flag;
+ (iOSReturnStatusCode)execute:(NSDictionary *)args;
+ (NSArray<CommandOption *> *)options;
+ (NSDictionary <NSString *, CommandOption *> *)optionDict; //keyed on short flag
+ (NSString *)usage;
@end
