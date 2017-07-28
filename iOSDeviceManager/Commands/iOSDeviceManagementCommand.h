
#import <Foundation/Foundation.h>
#import "CommandOption.h"
#import "Device.h"
#import "iOSReturnStatusCode.h"

@protocol iOSDeviceManagementCommand <NSObject>
+ (NSArray<NSString *> *)resourcesFromArgs:(NSDictionary *)args;
+ (Device *)deviceFromArgs:(NSDictionary *)args;
+ (Device *)simulatorFromArgs:(NSDictionary *)args;
+ (CodesignIdentity *)codesignIDFromArgs:(NSDictionary *)args;
+ (NSString *)name;
+ (void)printUsage;
+ (CommandOption *)optionForFlag:(NSString *)flag;
+ (CommandOption *)optionForPosition:(NSUInteger)index;
+ (CommandOption *)optionForAppPathOrBundleID:(NSString *)arg;
+ (iOSReturnStatusCode)execute:(NSDictionary *)args;
+ (NSArray<CommandOption *> *)options;
+ (NSDictionary <NSString *, CommandOption *> *)optionDict; //keyed on short flag
+ (NSString *)usage;
@end
