#import <Foundation/Foundation.h>

@interface ShasumProvider : NSObject
+ (NSString *)sha1FromData:(NSData *)data;
@end
