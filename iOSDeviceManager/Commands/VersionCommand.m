#import "VersionCommand.h"
#import "ConsoleWriter.h"

@implementation VersionCommand
+ (NSString *)name {
    return @"version";
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
    });
    return options;
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    ConsoleWrite(@"0.1");
    return iOSReturnStatusCodeEverythingOkay;
}
@end
