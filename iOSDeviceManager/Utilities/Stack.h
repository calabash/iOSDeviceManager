
#import <Foundation/Foundation.h>

@interface Stack : NSObject

@property (nonatomic, assign, readonly) NSUInteger count;

- (id)initWithArray:(NSArray*)array;
- (void)pushObject:(id)object;
- (void)pushObjects:(NSArray*)objects;
- (id)popObject;

@end
