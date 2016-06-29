
#import "TestParameters.h"

@interface NSString(Base64)
- (BOOL)isBase64;
@end

@implementation NSString(Base64)
- (BOOL)isBase64 {
    for (int i = 0; i < self.length; i++) {
        char c =  toupper([self characterAtIndex:i]);
        if (c < '0' || c > 'F') { return NO; }
    }
    return YES;
}
@end

@implementation TestParameters

+ (BOOL)isSimulatorID:(NSString *)did {
    NSArray <NSString *>*parts = [did componentsSeparatedByString:@"-"];
    NSUUID *u = [[NSUUID alloc] initWithUUIDString:did];
    return did.length == 36
        && u != nil
        && parts.count == 5
        && parts[0].length == 8
        && parts[1].length == 4
        && parts[2].length == 4
        && parts[3].length == 4
        && parts[4].length == 12;
}

+ (BOOL)isDeviceID:(NSString *)did {
    return did.length == 40 && [did isBase64];
}

@end
