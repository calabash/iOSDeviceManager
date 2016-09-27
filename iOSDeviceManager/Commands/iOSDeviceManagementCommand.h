
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
+ (NSString *)name;
+ (void)printUsage;
+ (CommandOption *)optionForFlag:(NSString *)flag;
+ (iOSReturnStatusCode)execute:(NSDictionary *)args;
+ (NSArray<CommandOption *> *)options;
+ (NSDictionary<NSString *, NSString *> *)parseArgs:(NSArray <NSString *> *)args
                                           exitCode:(int *)exitCode;
@end
