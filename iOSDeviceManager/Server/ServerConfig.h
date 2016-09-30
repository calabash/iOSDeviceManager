#import <Foundation/Foundation.h>

extern const int SERVER_PORT;

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
