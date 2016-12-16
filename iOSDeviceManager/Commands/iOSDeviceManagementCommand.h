
#import <Foundation/Foundation.h>
#import "CommandOption.h"

typedef NS_ENUM(int, iOSReturnStatusCode) {
    iOSReturnStatusCodeEverythingOkay = 0,
    iOSReturnStatusCodeGenericFailure,
    iOSReturnStatusCodeFalse,
    iOSReturnStatusCodeMissingArguments,
    iOSReturnStatusCodeInvalidArguments,
    iOSReturnStatusCodeInternalError,
    iOSReturnStatusCodeUnrecognizedCommand,
    iOSReturnStatusCodeUnrecognizedFlag,
    iOSReturnStatusCodeDeviceNotFound,
    iOSReturnStatusCodeNoValidCodesignIdentity
};

@protocol iOSDeviceManagementCommand <NSObject>
+ (NSString *)deviceIDFromArgs:(NSDictionary *)args;
+ (NSString *)name;
+ (void)printUsage;
+ (NSArray <NSString *> *)positionalArgNames;
+ (CommandOption *)optionForFlag:(NSString *)flag;
+ (iOSReturnStatusCode)execute:(NSDictionary *)args;
+ (NSArray<CommandOption *> *)options;
+ (NSDictionary <NSString *, CommandOption *> *)optionDict; //keyed on short flag
+ (NSString *)usage;
@end
