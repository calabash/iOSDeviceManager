
#import "ThreadUtils.h"

@implementation ThreadUtils
+ (void)runUntilAllComplete:(NSArray <NSOperation *> *)ops {
    NSOperationQueue *q = [NSOperationQueue new];
    q.maxConcurrentOperationCount = ops.count;
    [q addOperations:ops waitUntilFinished:YES];
}

+ (void)concurrentlyEnumerate:(NSArray *)array withBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block {
    NSMutableArray<NSBlockOperation *> *ops = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSBlockOperation *bop = [NSBlockOperation blockOperationWithBlock:^{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                block(obj, idx, stop);
            });
        }];
        [ops addObject:bop];
    }];
    [self runUntilAllComplete:ops];
}
@end
