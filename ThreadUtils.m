
#import "ThreadUtils.h"

@interface ConcurrentBlock : NSOperation {
    BOOL        executing;
    BOOL        finished;
    void(^block)(void);
}
+ (instancetype)withBlock:(void (^)(void))block;
- (void)completeOperation;
@end

@implementation ConcurrentBlock
+ (instancetype)withBlock:(void (^)(void))block {
    return [[self alloc] initWithBlock:block];
}

- (id)initWithBlock:(void (^)(void))bl {
    self = [super init];
    if (self) {
        finished = NO;
        executing = NO;
        block = bl;
    }
    return self;
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}

- (void)main {
    @try {
        block();
        [self completeOperation];
    }
    @catch(NSException *e) {
        NSLog(@"Error: %@", e);
    }
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    executing = NO;
    finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}
@end

@implementation ThreadUtils

+ (void)concurrentlyEnumerate:(NSArray *)array withBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block {
    NSOperationQueue *q = [NSOperationQueue new];
    q.maxConcurrentOperationCount = array.count;
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ConcurrentBlock *bl = [ConcurrentBlock withBlock:^{
            block(obj, idx, stop);
        }];
        [q addOperation:bl];
    }];
    [q waitUntilAllOperationsAreFinished];
}
@end
