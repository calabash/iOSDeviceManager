
#import <Foundation/Foundation.h>

@interface NSString (CBXUtils)
- (NSString *)replace:(NSString *)subs with:(NSString *)replacement;
- (NSString *)subsFrom:(NSUInteger)start length:(NSUInteger)length;
- (NSString *)plus:(NSString *)ending;
- (NSString *)joinPath:(NSString *)pathComponent;
- (NSArray <NSString *> *)matching:(NSString *)regex;
@end
