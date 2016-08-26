
#import "Entitlement.h"

@interface Entitlement ()

- (BOOL)hasNSArrayValue;
- (BOOL)hasNSStringValue;

+ (EntitlementComparisonResult)compareAssociatedDomains:(Entitlement *)profileEntitlement
                                         appEntitlement:(Entitlement *)appEntitlement;
@end

@implementation Entitlement

+ (EntitlementComparisonResult)compareProfileEntitlement:(Entitlement *)profileEntitlement
                                          appEntitlement:(Entitlement *)appEntitlement
                                  isAssociatedDomainsKey:(BOOL)isAssociatedDomainsKey {
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

    if (isAssociatedDomainsKey) {
        return [Entitlement compareAssociatedDomains:profileEntitlement
                                      appEntitlement:appEntitlement];
    }

    // App has the entitlement and so does the profile
    if ([appEntitlement hasNSStringValue] && [profileEntitlement hasNSStringValue]) {
         if ([appEntitlement.value isEqualToString:profileEntitlement.value]) {
             return ProfileHasKeyExactly;
         } else {
             return ProfileHasKey;
         }
    } else if ([appEntitlement hasNSArrayValue] && [profileEntitlement hasNSArrayValue]) {
        NSArray *appArray = (NSArray *)appEntitlement.value;
        NSArray *profileArray = (NSArray *)profileEntitlement.value;

        if (appArray.count > profileArray.count) {
            return ProfileDoesNotHaveRequiredKey;
        } else if (appArray.count < profileArray.count) {
            // TODO scale this value to make _more_ entitlements less attractive
            //  MAX(ProfileHasKey * (profile.count - app.count), ProfileHasKey)
            return ProfileHasKey;
        } else {
            NSSet *appSet = [NSSet setWithArray:appArray];
            NSSet *profileSet = [NSSet setWithArray:profileArray];
            if ([appSet isEqualToSet:profileSet]) {
                return ProfileHasKeyExactly;
            } else {
                return ProfileHasKey;
            }
        }
    } else {
        // Mixed Array and String values.  If this is not an AssociatedDomain key, we
        // don't know how to handle it.  Log and punt.
        NSLog(@"WARN: Unexpected.");
        NSLog(@"WARN: Entitlement key has mixed string and array values");
        NSLog(@"WARN:                     key: %@", appEntitlement.key);
        NSLog(@"WARN:        app entitlements: %@", appEntitlement.value);
        NSLog(@"WARN:    profile entitlements: %@", appEntitlement.value);
        NSLog(@"WARN: Assuming that this profile does match.");
        return ProfileDoesNotHaveRequiredKey;
    }
}


/*
Tries to match associated-domains entitlements where the values can both be
either arrays or strings.

The "*" character is treated as a trump card, such that:

1. if profile's value is '*' then it is a match, and
2. if app's value is star but profile's value is anything but '*', it is not a match.
*/
+ (EntitlementComparisonResult)compareAssociatedDomains:(Entitlement *)profileEntitlement
                                         appEntitlement:(Entitlement *)appEntitlement {
    if ([profileEntitlement hasNSArrayValue]) {
        if ([appEntitlement hasNSArrayValue]) {
            return [Entitlement compareProfileEntitlement:profileEntitlement
                                           appEntitlement:appEntitlement
                                   isAssociatedDomainsKey:NO];
        } else {
            if ([appEntitlement.value isEqualToString:@"*"]) {
                /* presumably, any array of entries is 'less' than '*' */
                return ProfileDoesNotHaveRequiredKey;
            } else {
                // TODO in this case shouldn't we see if the app string is in the
                // profile array? The calabash-tool did not make this check.
            }
        }
    } else {
        if ([appEntitlement hasNSArrayValue]) {
             if (![profileEntitlement.value isEqualToString:@"*"]) {
                 return ProfileDoesNotHaveRequiredKey;
             } else {
                 // TODO this is a match exactly case, right?
                 // The app has an array of domains.  The profile has "*", so this
                 // is an exact match? Should it be preferred over an exact array match?
                 // Should it preferred over an array match with more than the required
                 // domains?
                 //
                 // (>_>)
             }
        } else {
            if ([appEntitlement.value isEqualToString:profileEntitlement.value]) {
                  return ProfileHasKeyExactly;
            }
        }
    }

    return ProfileHasKey;
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
