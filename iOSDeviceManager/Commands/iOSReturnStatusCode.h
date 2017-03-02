typedef NS_ENUM(int, iOSReturnStatusCode) {
    iOSReturnStatusCodeEverythingOkay = 0,
    iOSReturnStatusCodeGenericFailure = 1,
    iOSReturnStatusCodeFalse = 2,
    iOSReturnStatusCodeMissingArguments = 3,
    iOSReturnStatusCodeInvalidArguments = 4,
    iOSReturnStatusCodeInternalError = 5,
    iOSReturnStatusCodeUnrecognizedCommand = 6,
    iOSReturnStatusCodeUnrecognizedFlag = 7,
    iOSReturnStatusCodeDeviceNotFound = 8,
    iOSReturnStatusCodeNoValidCodesignIdentity = 9
};
