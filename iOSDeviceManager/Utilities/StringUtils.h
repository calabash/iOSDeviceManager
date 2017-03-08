
#import <Foundation/Foundation.h>

@interface NSString (CBXUtils)
- (NSString *)replace:(NSString *)subs with:(NSString *)replacement;
- (NSString *)subsFrom:(NSInteger)start length:(NSInteger)length;
- (NSString *)plus:(NSString *)ending;
- (NSString *)joinPath:(NSString *)pathComponent;
- (NSArray <NSString *> *)matching:(NSString *)regex;
- (NSArray <NSString *> *)caseInsensitiveMatching:(NSString *)regex;
@end
