
#import "ResignObjectCommand.h"
#import "Codesigner.h"
#import "ConsoleWriter.h"

static NSString *const RESIGN_OBJECT_OPTION_NAME = @"resign-object-path";

@implementation ResignObjectCommand
+ (NSString *)name {
    return @"resign-object";
}

// Example: resign_object calabash_dylib -c <identity>
+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withPosition:0
                                            optionName:RESIGN_OBJECT_OPTION_NAME
                                                  info:@"Path to dylib or framework to resign in page"
                                              required:YES
                                            defaultVal:nil]];
        [options addObject:[CommandOption withPosition:1
                                            optionName:CODESIGN_ID_OPTION_NAME
                                                  info:@"Codesign identity shasum or name"
                                              required:YES
                                            defaultVal:nil]];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    CodesignIdentity *codesignID = [self codesignIDFromArgs:args];
    NSString *resignObjectPath = args[RESIGN_OBJECT_OPTION_NAME];
    
    if (!codesignID) {
        ConsoleWriteErr(@"Failed to find codesign identity");
        return iOSReturnStatusCodeInvalidArguments;
    }
    
    @try {
       [Codesigner resignObject:resignObjectPath codesignIdentity:codesignID];
    } @catch (NSException *e) {
        ConsoleWriteErr(@"Failed to resign object due to error: %@", e);
        return iOSReturnStatusCodeInternalError;
    }
    
    return iOSReturnStatusCodeEverythingOkay;
}
@end
