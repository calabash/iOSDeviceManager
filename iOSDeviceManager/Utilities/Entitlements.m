
#import "Entitlements.h"
#import "ShellRunner.h"
#import "Entitlement.h"

static NSString *const kAssociatedDomainsEntitlementKey = @"com.apple.developer.associated-domains";

@interface Entitlements ()

+ (NSDictionary *)dictionaryOfEntitlementsWithBundlePath:(NSString *)bundlePath;
+ (NSArray<NSString *> *)entitlementComparisonKeys;

@property(copy, readonly) NSDictionary *dictionary;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

@implementation Entitlements

+ (NSDictionary *)dictionaryOfEntitlementsWithBundlePath:(NSString *)bundlePath {
    NSArray<NSString *> *args;
    args = @[@"codesign", @"-d", @"--entitlements", @":-", bundlePath];

    ShellResult *result = [ShellRunner xcrun:args timeout:10];

    if (!result.success) {
        NSLog(@"ERROR:  Could not extract entitlements from app:\n   %@", bundlePath);
        NSLog(@"ERROR:  with command:\n    %@", result.command);
        if (result.didTimeOut) {
            NSLog(@"ERROR: codesign timed out after %@ seconds", @(result.elapsed));
        } else {
            NSLog(@"=== STDERR ===");
            NSLog(@"%@", result.stderr);
        }
        return nil;
    }

    NSData *data = [result.stdout dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *plist;

    plist = [NSPropertyListSerialization propertyListWithData:data
                                                      options:NSPropertyListImmutable
                                                       format:nil
                                                        error:&error];

    if (!plist || plist.count == 0) {
        NSLog(@"ERROR: Could not parse plist to dictionary:");
        NSLog(@"=== PLIST BEGIN ===");
        NSLog(@"%@", result.stdout);
        NSLog(@"=== PLIST END ===");
        NSLog(@"ERROR: %@", [error localizedDescription]);
        return nil;
    }
    return plist;
}

+ (Entitlements *)entitlementsWithBundlePath:(NSString *)bundlePath {
    NSDictionary *dictionary;
    dictionary = [Entitlements dictionaryOfEntitlementsWithBundlePath:bundlePath];

    if (!dictionary) { return nil; }

    return [[Entitlements alloc] initWithDictionary:dictionary];
}

+ (Entitlements *)entitlementsWithDictionary:(NSDictionary *)dictionary {
    return [[Entitlements alloc] initWithDictionary:dictionary];
}

+ (NSArray<NSString *> *)entitlementComparisonKeys {
    return
    @[
      // Requires special matching.
      kAssociatedDomainsEntitlementKey,

      // String Values
      @"com.apple.developer.ubiquity-kvstore-identifier",
      @"com.apple.developer.icloud-services",
      @"aps-environment",
      @"com.apple.developer.default-data-protection",

      // Array Values
      @"keychain-access-groups",
      @"com.apple.security.application-groups",
      @"com.apple.developer.in-app-payments",
      @"com.apple.developer.pass-type-identifiers",
      @"com.apple.developer.icloud-container-environment",
      @"com.apple.developer.icloud-container-identifiers",
      @"com.apple.developer.icloud-container-development-container-identifiers",
      @"com.apple.developer.ubiquity-container-identifiers",
      @"com.apple.developer.networking.com.apple.developer.in-app-payments.api"
      ];
}

+ (NSInteger)rankByComparingProfileEntitlements:(Entitlements *)profileEntitlements
                                appEntitlements:(Entitlements *)appEntitlements {
    NSArray<NSString *> *keys = [Entitlements entitlementComparisonKeys];

    Entitlement *appEntitlement, *profileEntitlement;

    NSInteger sum = 0;
    EntitlementComparisonResult current;
    BOOL isAssociatedDomainsKey;

    for(NSString *key in keys) {
        isAssociatedDomainsKey = [kAssociatedDomainsEntitlementKey isEqualToString:key];

        appEntitlement = [Entitlement entitlementWithKey:key
                                                   value:appEntitlements[key]];
        profileEntitlement = [Entitlement entitlementWithKey:key
                                                       value:profileEntitlements[key]];
        current = [Entitlement compareProfileEntitlement:profileEntitlement
                                          appEntitlement:appEntitlement
                                  isAssociatedDomainsKey:isAssociatedDomainsKey];
        if (current == ProfileDoesNotHaveRequiredKey) {
            sum = ProfileDoesNotHaveRequiredKey;
            break;
        } else {
            sum = sum + (NSInteger)current;
        }
    };
    return sum;
}

@synthesize dictionary = _dictionary;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _dictionary = dictionary;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"#<Entitlements: %@>", self.dictionary];
}

- (id)objectForKeyedSubscript:(NSString *)key {
    return self.dictionary[key] ?: nil;
}

- (Entitlements *)entitlementsByReplacingApplicationIdentifier:(NSString *)applicationIdentifier {
    NSMutableDictionary *mutable = [self.dictionary mutableCopy];
    mutable[@"application-identifier"] = applicationIdentifier;
    return [Entitlements entitlementsWithDictionary:mutable];
}

- (BOOL)writeToFile:(NSString *)path {
    return [self.dictionary writeToFile:path atomically:YES];
}

@end
