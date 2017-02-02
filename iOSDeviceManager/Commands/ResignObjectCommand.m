#import "ResignObjectCommand.h"
#import "Codesigner.h"
#import "ConsoleWriter.h"

static NSString *const CODESIGN_ID_FLAG = @"-c";
static NSString *const RESIGN_OBJECT_PATH_FLAG = @"-ro";

@implementation ResignObjectCommand
+ (NSString *)name {
    return @"resign_object";
}

// Example: resign_object calabash_dylib -c <identity>
+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:CODESIGN_ID_FLAG
                                               longFlag:@"--codesign-id"
                                             optionName:@"codesign-identity"
                                                   info:@"Codesign identity"
                                               required:YES
                                             defaultVal:nil]];
        [options addObject:[CommandOption withShortFlag:RESIGN_OBJECT_PATH_FLAG
                                               longFlag:@"--resign-object"
                                             optionName:@"path/to/resign-object"
                                                   info:@"Path to dylib or framework to resign in place."
                                               required:NO
                                             defaultVal:nil]];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    NSString *codesignID = [self codesignIDFromArgs:args];
    NSString *resignObjectPath = [self resignObjectFromArgs:args];
    
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
