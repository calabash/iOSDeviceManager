
#import "Entitlement.h"

@interface Entitlement ()

- (BOOL)hasNSArrayValue;
- (BOOL)hasNSStringValue;

+ (EntitlementComparisonResult)compareEntitlements:(Entitlement *)profileEntitlement
                                         appEntitlement:(Entitlement *)appEntitlement;
@end

@implementation Entitlement

+ (EntitlementComparisonResult)compareProfileEntitlement:(Entitlement *)profileEntitlement
                                          appEntitlement:(Entitlement *)appEntitlement {
    if (appEntitlement.value && !profileEntitlement.value) {
        return ProfileDoesNotHaveRequiredKey;
    }

    if (!appEntitlement.value) {
        if (!profileEntitlement.value) {
            return AppNorProfileHasKey;
        } else {
            return ProfileHasUnRequiredKey;
        }
    }

    if ([appEntitlement hasNSArrayValue]) {
        if ([profileEntitlement hasNSArrayValue]) {
            // App => array
            // Prof => array
            NSArray *appArray = (NSArray *)appEntitlement.value;
            NSArray *profArray = (NSArray *)profileEntitlement.value;

            if (appArray.count > profArray.count) {
                return ProfileDoesNotHaveRequiredKey;
            } else if (appArray.count < profArray.count) {
                // Prefer _less_ entitlements
                return (profArray.count - appArray.count) * ProfileHasKey;
            } else {
                NSSet *appSet = [NSSet setWithArray:appArray];
                NSSet *profSet = [NSSet setWithArray:profArray];
                if ([appSet isEqualToSet:profSet]) {
                    return ProfileHasKeyExactly;
                } else {
                    return ProfileHasKey;
                }
            }
        } else if ([profileEntitlement hasNSStringValue]) {
            // App => array
            // Prof => string
            if ([profileEntitlement.value isEqualToString:@"*"]) {
                return ProfileHasKey;
            } else {
                return ProfileDoesNotHaveRequiredKey;
            }
        } else {
            // WTF?!
            // Somehow we've reached a point where the profile entitlement is
            // neither string nor array.  We don't know what to do here
        }

    } else if ([appEntitlement hasNSStringValue]) {
        if ([profileEntitlement hasNSStringValue]) {
            // App => string
            // Prof => string
            if ([appEntitlement.value isEqualToString:profileEntitlement.value]) {
                return ProfileHasKeyExactly;
            } else {
                return ProfileHasKey;
            }
        } else if ([profileEntitlement hasNSArrayValue]) {
            // App => string
            // Prof => array
            if ([appEntitlement.value isEqualToString:@"*"]) {
                return ProfileDoesNotHaveRequiredKey;
            } else {
                NSArray *profArray = (NSArray *)profileEntitlement.value;
                if ([profArray containsObject:appEntitlement.value]) {
                    return ProfileHasKey;
                } else {
                    return ProfileDoesNotHaveRequiredKey;
                }
            }
        } else {
            // WTF?!
            // Somehow we've reached a point where the profile entitlement is
            // neither string nor array.  We don't know what to do here
        }
    } else {
        // WTF?!
        // Somehow we've reached a point where the app entitlement is
        // neither string nor array.  We don't know what to do here
    }
    // We should never reach this point... if we reached this point, we've hit a
    // WTF branch.  I am assuming that if we hit a WTF, we should assume it's not
    // a match
    NSLog(@"ERROR: Unable to match entitlement, unexpected type(s)");
    NSLog(@"ERROR:                       key: %@", profileEntitlement.key);
    NSLog(@"ERROR:  profile entitlement type: %@", [profileEntitlement.value class]);
    NSLog(@"ERROR:      app entitlement type: %@", [appEntitlement.value class]);
    return ProfileDoesNotHaveRequiredKey;
}

@synthesize key = _key;
@synthesize value = _value;

+ (Entitlement *)entitlementWithKey:(NSString *)key value:(id)value {
    return [[Entitlement alloc] initWithKey:key
                                      value:value];
}

- (instancetype)initWithKey:(NSString *)key value:(id)value {
    self = [super init];
    if (self) {
        _key = key;
        _value = value;
    }
    return self;
}

- (BOOL)hasNSArrayValue {
    return [[self.value class] isSubclassOfClass:[NSArray class]];
}

- (BOOL)hasNSStringValue {
    return [[self.value class] isSubclassOfClass:[NSString class]];
}

@end
