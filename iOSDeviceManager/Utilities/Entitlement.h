
#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    // Reject
    ProfileDoesNotHaveRequiredKey = -1,

    AppNorProfileHasKey = 0,

    // Accept
    ProfileHasKeyExactly = 1,
    ProfileHasKey = 100,
    ProfileHasUnRequiredKey = 1000,
} EntitlementComparisonResult;

@interface Entitlement : NSObject

+ (EntitlementComparisonResult)compareProfileEntitlement:(Entitlement *)profileEntitlement
                                          appEntitlement:(Entitlement *)appEntitlement;

+ (Entitlement *)entitlementWithKey:(NSString *)key
                              value:(id)value;

@property(copy, readonly) NSString *key;
@property(strong, readonly) id value;

- (instancetype)initWithKey:(NSString *)key
                      value:(id)value;

@end
