
#import "StringUtils.h"

@implementation NSString(CBXUtils)
- (NSString *)replace:(NSString *)subs with:(NSString *)replacement {
    return [self stringByReplacingOccurrencesOfString:subs withString:replacement];
}
- (NSString *)subsFrom:(NSInteger)start length:(NSInteger)length {
    return [self substringWithRange:NSMakeRange(start, length)];
}
- (NSString *)plus:(NSString *)ending {
    return [self stringByAppendingString:ending];
}

- (NSString *)joinPath:(NSString *)pathComponent {
    return [self stringByAppendingPathComponent:pathComponent];
}

- (NSArray <NSString *> *)matching:(NSString *)regexStr options:(NSRegularExpressionOptions)options {
    NSError *e;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexStr
                                                                           options:options
                                                                             error:&e];
    NSAssert(e == nil, @"Error creating regex '%@': %@", regex, e);

    NSMutableArray *matches = [NSMutableArray array];
    [regex enumerateMatchesInString:self
                            options:0
                              range:NSMakeRange(0, self.length)
                         usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        NSString *match = [self substringWithRange:[result range]];
        [matches addObject:match];
    }];
    return matches;
}

- (NSArray <NSString *> *)matching:(NSString *)regex {
    return [self matching:regex options:0];
}

- (NSArray <NSString *> *)caseInsensitiveMatching:(NSString *)regex {
    return [self matching:regex options:NSRegularExpressionCaseInsensitive];
}
@end
