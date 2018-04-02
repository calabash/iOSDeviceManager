#import "MobileProfile.h"
#import "Entitlements.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "Entitlement.h"
#import "ConsoleWriter.h"
#import "StringUtils.h"
#import "JSONUtils.h"

@interface Entitlements ()

@property(copy, readonly) NSDictionary *dictionary;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

@implementation Entitlements

+ (NSDictionary *)dictionaryOfEntitlementsWithBundlePath:(NSString *)bundlePath {
    NSArray<NSString *> *args;
    args = @[@"codesign", @"-d", @"--entitlements", @":-", bundlePath];

    ShellResult *result = [ShellRunner xcrun:args timeout:10];

    if (!result.success) {
        ConsoleWriteErr(@" Could not extract entitlements from app:\n   %@", bundlePath);
        ConsoleWriteErr(@" with command:\n    %@", result.command);
        if (result.didTimeOut) {
            ConsoleWriteErr(@"codesign timed out after %@ seconds", @(result.elapsed));
        } else {
            ConsoleWriteErr(@"=== STDERR ===");
            ConsoleWriteErr(@"%@", result.stderrStr);
        }
        return nil;
    }

    NSData *data = [result.stdoutStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *plist;

    plist = [NSPropertyListSerialization propertyListWithData:data
                                                      options:NSPropertyListImmutable
                                                       format:nil
                                                        error:&error];

    if (!plist || plist.count == 0) {
        ConsoleWriteErr(@"Could not parse plist to dictionary:");
        ConsoleWriteErr(@"=== PLIST BEGIN ===");
        ConsoleWriteErr(@"%@", result.stdoutStr);
        ConsoleWriteErr(@"=== PLIST END ===");
        ConsoleWriteErr(@"%@", [error localizedDescription]);
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

+ (NSInteger)rankByComparingProfileEntitlements:(Entitlements *)profileEntitlements
                                appEntitlements:(Entitlements *)appEntitlements {
    NSArray<NSString *> *keys = [appEntitlements.dictionary allKeys];
    
    Entitlement *appEntitlement, *profileEntitlement;

    NSInteger sum = 0;
    EntitlementComparisonResult current;

    for(NSString *key in keys) {
        appEntitlement = [Entitlement entitlementWithKey:key
                                                   value:appEntitlements[key]];
        profileEntitlement = [Entitlement entitlementWithKey:key
                                                       value:profileEntitlements[key]];
        current = [Entitlement compareProfileEntitlement:profileEntitlement
                                          appEntitlement:appEntitlement];
        if (current == ProfileDoesNotHaveRequiredKey) {
            sum = ProfileDoesNotHaveRequiredKey;
            break;
        } else {
            sum = sum + (NSInteger)current;
        }
    };
    return sum;
}

+ (void)compareEntitlementsWithProfile:(MobileProfile *)profile app:(Application *)app {
    
    Entitlement *appEntitlement, *profileEntitlement;
    Entitlements *profileEntitlements = [profile entitlements];
    Entitlements *appEntitlements = [Entitlements entitlementsWithBundlePath:app.path];
    EntitlementComparisonResult comparison;

    NSArray<NSString *> *keys = [appEntitlements.dictionary allKeys];
    LogInfo(@"Checking for profile and app entitlement discrepancy");
    for (NSString *key in keys) {
        appEntitlement = [Entitlement entitlementWithKey:key
                                                   value:appEntitlements[key]];
        profileEntitlement = [Entitlement entitlementWithKey:key
                                                       value:profileEntitlements[key]];
        comparison = [Entitlement compareProfileEntitlement:profileEntitlement appEntitlement:appEntitlement];
        if (comparison == ProfileDoesNotHaveRequiredKey) {
            LogInfo(@"Profile does not have app entitlement key: %@", key);
        } else if (comparison == ProfileHasKey) {
            LogInfo(@"Profile has non-exact value for app entitlement key: %@", key);
        }
    }
}

@synthesize dictionary = _dictionary;

- (NSInteger)count {
    return self.dictionary.count;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _dictionary = dictionary;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"#<Entitlements: %@>", self.dictionary.pretty];
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

- (NSString *)applicationIdentifier {
    return self[@"application-identifier"];
}

/*
    ABCDEF12345.com.my.app => com.my.app
 */
- (NSString *)applicationIdentifierWithoutPrefix {
    NSString *teamID = self[@"com.apple.developer.team-identifier"];
    NSString *appID = [self applicationIdentifier];
    return [appID replace:[NSString stringWithFormat:@"%@.", teamID] with:@""];
}

@end
