#import "DeviceUtils.h"

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

@implementation DeviceUtils

+ (BOOL)isSimulatorID:(NSString *)did {
    return [[NSUUID alloc] initWithUUIDString:did] != nil;
}

+ (BOOL)isDeviceID:(NSString *)did {
    return did.length == 40 && [did isBase64];
}

@end
