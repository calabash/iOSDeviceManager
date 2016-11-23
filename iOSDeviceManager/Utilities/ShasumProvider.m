#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "ShasumProvider.h"

@implementation ShasumProvider

+ (NSString *)sha1FromData:(NSData *)data {
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];

    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);

    NSMutableString *sha1 = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

    for (int i=0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        NSString *character = [NSString stringWithFormat:@"%02x", digest[i]];
        [sha1 appendString:character];
    }

    return [NSString stringWithString:sha1];
}

@end
