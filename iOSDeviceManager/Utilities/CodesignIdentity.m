
#import "CodesignIdentity.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "MobileProfile.h"
#import "Entitlements.h"
#import "Entitlement.h"

@interface CodesignIdentity ()

+ (NSArray<CodesignIdentity *> *)validIOSDeveloperIdentities;
+ (NSArray<CodesignIdentity *> *)validCodesigningIdentities;
+ (ShellResult *)askSecurityForValidCodesignIdentities;

@property(copy) NSString *shasum;
@property(copy) NSString *name;

- (BOOL)isEqualToCodesignIdentity:(CodesignIdentity *)other;

@end

@implementation CodesignIdentity

+ (CodesignIdentity *)identityForAppBundle:(NSString *)appBundle
                                  deviceId:(NSString *)deviceId {
    Entitlements *appEnts = [Entitlements entitlementsWithBundlePath:appBundle];
    if (!appEnts) {
        return nil;
    }

    if (![self validIOSDeveloperIdentities]) {
        return nil;
    }

    if (![MobileProfile nonExpiredIOSProfiles]) {
        return nil;
    }
    CodesignIdentity *bestIdentity = nil;
    NSInteger bestIdentityRank = NSIntegerMax;
    
    for(CodesignIdentity *identity in [self validIOSDeveloperIdentities]) {
        for(MobileProfile *profile in [MobileProfile nonExpiredIOSProfiles]) {
            if ([profile isValidForDeviceUDID:deviceId identity:identity]) {
                NSInteger rank = [Entitlements
                                  rankByComparingProfileEntitlements:profile.Entitlements
                                  appEntitlements:appEnts];

                if (rank != ProfileDoesNotHaveRequiredKey && rank < bestIdentityRank) {
                    bestIdentity = identity;
                    bestIdentityRank = rank;
                }
            }
        }
    }

    return bestIdentity;
}

+ (NSString *)codeSignIdentityFromEnvironment {
    return [[NSProcessInfo processInfo] environment][@"CODE_SIGN_IDENTITY"];
}

+ (NSArray<CodesignIdentity *> *)validIOSDeveloperIdentities {
    NSArray<CodesignIdentity *> *identities;
    identities = [CodesignIdentity validCodesigningIdentities];

    if (!identities) { return nil; }

    NSPredicate *filter;
    filter = [NSPredicate predicateWithBlock:^BOOL(CodesignIdentity *identity,
                                                   NSDictionary *bindings) {
        return [identity isIOSDeveloperIdentity];
    }];

    return [identities filteredArrayUsingPredicate:filter];
}

+ (NSArray<CodesignIdentity *> *)validCodesigningIdentities {
    ShellResult *result = [CodesignIdentity askSecurityForValidCodesignIdentities];

    if (!result) { return nil; }

    NSArray<NSString *> *lines = result.stdoutLines;

    NSRegularExpression *nameRegex;
    nameRegex = [NSRegularExpression regularExpressionWithPattern:@"\"(.*?)\""
                                                          options:0
                                                            error:NULL];
    NSRegularExpression *identifierRegex;
    identifierRegex = [NSRegularExpression regularExpressionWithPattern:@"([A-F0-9]{40})"
                                                                options:0
                                                                  error:NULL];
    NSMutableArray<CodesignIdentity *> *identities = [@[] mutableCopy];

    NSString *name;
    NSString *shasum;
    NSRange range;
    NSRange match;
    CodesignIdentity *identity;

    for (NSString *line in lines) {
        range = NSMakeRange(0, [line length]);
        match = [nameRegex rangeOfFirstMatchInString:line
                                             options:0
                                               range:range];
        if (match.location != NSNotFound) {
            // Strip the quotes
            NSRange strip = NSMakeRange(match.location + 1, match.length - 2);
            name = [line substringWithRange:strip];
        } else {
            name = nil;
        }

        range = NSMakeRange(0, [line length]);
        match = [identifierRegex rangeOfFirstMatchInString:line
                                                   options:0
                                                     range:range];
        if (match.location != NSNotFound) {
            shasum = [[line substringWithRange:match] uppercaseString];
        } else {
            shasum = nil;
        }

        if (shasum && name) {
            identity = [[CodesignIdentity alloc] initWithShasum:shasum name:name];
            if (![identities containsObject:identity]) {
                [identities addObject:identity];
            }
        }
    }
    return [NSArray arrayWithArray:identities];
}

+ (ShellResult *)askSecurityForValidCodesignIdentities {
    NSArray *args = @[@"security", @"find-identity", @"-v", @"-p", @"codesigning"];

    ShellResult *result = [ShellRunner xcrun:args timeout:30];

    if (!result.success) {
        NSLog(@"Could not find valid codesign identities with:\n    %@", result.command);
        if (result.didTimeOut) {
            NSLog(@"Command timed out after %@ seconds", @(result.elapsed));
        } else {
            NSLog(@"=== STDERR ===");
            NSLog(@"%@", result.stderrStr);
        }
        return nil;
    }

    return result;
}

#pragma mark - Instance Methods

@synthesize shasum = _shasum;
@synthesize name = _name;

- (instancetype)initWithShasum:(NSString *)shasum name:(NSString *)name {
    self = [super init];
    if (self) {
        _shasum = shasum;
        _name = name;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"#<CodesignIdentity: %@ : %@>", [self shasum], [self name]];
}

- (BOOL)isEqualToCodesignIdentity:(CodesignIdentity *)other {
    if (!other) {
        return NO;
    } else {
        return [self.shasum isEqualToString:other.shasum] &&
        [self.name isEqualToString:other.name];
    }
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[CodesignIdentity class]]) {
        return NO;
    }

    return [self isEqualToCodesignIdentity:object];
}

- (NSUInteger)hash {
    return [self.name hash] ^ [self.shasum hash];
}

- (BOOL)isIOSDeveloperIdentity {
    return [self.name containsString:@"iPhone Developer"];
}

- (id)copyWithZone:(NSZone *)zone {
    CodesignIdentity *copy = [[CodesignIdentity alloc] init];

    if (copy) {
        copy.shasum = [self.shasum copyWithZone:zone];
        copy.name = [self.name copyWithZone:zone];
    }

    return copy;
}

@end
