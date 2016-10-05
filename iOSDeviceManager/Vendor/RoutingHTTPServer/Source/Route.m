#import "Route.h"

@implementation Route

@synthesize regex;
@synthesize handler;
@synthesize target;
@synthesize selector;
@synthesize keys;


+ (instancetype)routeWithPath:(NSString *)path target:(id)target selector:(SEL)selector {
    Route *r = [self routeWithPath:path];
    r.target = target;
    r.selector = selector;
    return r;
}

+ (instancetype)routeWithPath:(NSString *)path block:(RequestHandler)block {
    Route *r = [self routeWithPath:path];
    r.handler = block;
    return r;
}

+ (instancetype)routeWithPath:(NSString *)path {
    Route *route = [self new];
    NSMutableArray *keys = [NSMutableArray array];
    
    if ([path length] > 2 && [path characterAtIndex:0] == '{') {
        // This is a custom regular expression, just remove the {}
        path = [path substringWithRange:NSMakeRange(1, [path length] - 2)];
    } else {
        NSRegularExpression *regex = nil;
        
        // Escape regex characters
        regex = [NSRegularExpression regularExpressionWithPattern:@"[.+()]" options:0 error:nil];
        path = [regex stringByReplacingMatchesInString:path options:0 range:NSMakeRange(0, path.length) withTemplate:@"\\\\$0"];
        
        // Parse any :parameters and * in the path
        regex = [NSRegularExpression regularExpressionWithPattern:@"(:(\\w+)|\\*)"
                                                          options:0
                                                            error:nil];
        NSMutableString *regexPath = [NSMutableString stringWithString:path];
        __block NSInteger diff = 0;
        [regex enumerateMatchesInString:path options:0 range:NSMakeRange(0, path.length)
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                 NSRange replacementRange = NSMakeRange(diff + result.range.location, result.range.length);
                                 NSString *replacementString;
                                 
                                 NSString *capturedString = [path substringWithRange:result.range];
                                 if ([capturedString isEqualToString:@"*"]) {
                                     [keys addObject:@"wildcards"];
                                     replacementString = @"(.*?)";
                                 } else {
                                     NSString *keyString = [path substringWithRange:[result rangeAtIndex:2]];
                                     [keys addObject:keyString];
                                     replacementString = @"([^/]+)";
                                 }
                                 
                                 [regexPath replaceCharactersInRange:replacementRange withString:replacementString];
                                 diff += replacementString.length - result.range.length;
                             }];
        
        path = [NSString stringWithFormat:@"^%@$", regexPath];
    }
    
    route.regex = [NSRegularExpression regularExpressionWithPattern:path options:NSRegularExpressionCaseInsensitive error:nil];
    if ([keys count] > 0) {
        route.keys = keys;
    }
    
    return route;
}

@end
