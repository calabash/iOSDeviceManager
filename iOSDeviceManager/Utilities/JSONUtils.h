
#import <Foundation/Foundation.h>

@interface NSDictionary (CBXUtils)
- (NSString *)pretty;
- (BOOL)hasKey:(id<NSCopying>)key;
- (BOOL)hasValue:(id)val;
@end

@interface NSArray (CBXUtils)
- (NSString *)pretty;
@end
