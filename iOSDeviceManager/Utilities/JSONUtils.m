
#import "JSONUtils.h"

@interface JSONUtils : NSObject
+ (NSString *)beautify:(id)json;
@end

@implementation JSONUtils

+ (NSString *)beautify:(id)json {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];

    if (!jsonData) {
        NSLog(@"%@: error: %@", NSStringFromSelector(_cmd), error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

@end

@implementation NSDictionary (CBXUtils)
- (NSString *)pretty {
    return [JSONUtils beautify:self];
}

- (BOOL)hasKey:(id<NSCopying>)key {
    return [[self allKeys] containsObject:key];
}

- (BOOL)hasValue:(id)val {
    return [[self allValues] containsObject:val];
}
@end

@implementation NSArray (CBXUtils)
- (NSString *)pretty {
    return [JSONUtils beautify:self];
}
@end
