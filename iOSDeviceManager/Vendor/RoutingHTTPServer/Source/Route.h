#import <Foundation/Foundation.h>
#import "RoutingHTTPServer.h"

@interface Route : NSObject

@property (nonatomic) NSRegularExpression *regex;
@property (nonatomic, copy) RequestHandler handler;

#if __has_feature(objc_arc_weak)
@property (nonatomic, weak) id target;
#else
@property (nonatomic, assign) id target;
#endif

@property (nonatomic, assign) SEL selector;
@property (nonatomic) NSArray *keys;

/*
 Static route constructors
 */
+ (instancetype)routeWithPath:(NSString *)path target:(id)target selector:(SEL)selector;
+ (instancetype)routeWithPath:(NSString *)path block:(RequestHandler)block;

@end
