typedef NS_ENUM(NSUInteger, iOSReturnStatusCode) {
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
