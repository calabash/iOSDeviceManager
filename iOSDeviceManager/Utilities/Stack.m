
#import "Stack.h"

@interface Stack()
@property (nonatomic, strong) NSMutableArray *objects;
@end

@implementation Stack

- (NSUInteger)count {
    return _objects.count;
}

- (id)initWithArray:(NSArray*)array {
    if (self = [super init]) {
        _objects = [array mutableCopy];
    }
    
    return self;
}

- (void)pushObject:(id)object {
    if (object) {
        [_objects addObject:object];
    }
}

- (void)pushObjects:(NSArray*)objects {
    for (id object in objects) {
        [_objects addObject:object];
    }
}

- (id)popObject {
    id object = [_objects lastObject];
    if (object) {
        [_objects removeLastObject];
    }
    
    return object;
}

@end
