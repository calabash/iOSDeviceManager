
#import "MobileProfile.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "Certificate.h"
#import "Entitlements.h"
#import "Entitlement.h"
#import "CodesignIdentity.h"

@interface MobileProfile ()

+ (NSString *)profilesDirectory;
+ (NSArray<NSString *> *)arrayOfProfilePaths;
+ (NSString *)stringByExportingProfileWithSecurity:(NSString *)path;
+ (NSDictionary *)dictionaryByExportingProfileWithSecurity:(NSString *) path;

@property(copy, readonly) NSArray<Certificate *> *certificates;
@property(assign) NSInteger rank;

- (instancetype)initWithDictionary:(NSDictionary *)info
                              path:(NSString *)path;
@end

@implementation MobileProfile

#pragma mark - Class Methods

+ (NSString *)profilesDirectory {
    NSString *path = @"Library/MobileDevice/Provisioning Profiles";
    return [NSHomeDirectory() stringByAppendingPathComponent:path];
}

+ (NSArray<NSString *> *)arrayOfProfilePaths {
    NSString *directory = [MobileProfile profilesDirectory];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray<NSString *> *contents = [manager contentsOfDirectoryAtPath:directory
                                                                 error:&error];
    if (!contents) {
        NSLog(@"ERROR: Could not find any mobileprovision files in:\n"
              "  %@", directory);
        NSLog(@"ERROR: %@", [error localizedDescription]);
        return nil;
    } else if (contents.count == 0) {
        NSLog(@"ERROR: Could not find any mobileprovision files in:\n"
              "  %@", directory);
        NSLog(@"ERROR: There was no error, but there were no files in that directory");
        return nil;
    }

    NSPredicate *predicate;
    predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH '.mobileprovision'"];

    NSArray *filtered = [contents filteredArrayUsingPredicate:predicate];
    NSMutableArray<NSString *> *paths = [@[] mutableCopy];

    for(NSString *name in filtered) {
        [paths addObject:[directory stringByAppendingPathComponent:name]];
    }

    return [NSArray arrayWithArray:paths];
}

+ (NSString *)stringByExportingProfileWithSecurity:(NSString *)path {
    NSString *uuid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *name = [NSString stringWithFormat:@"%@.plist", uuid];
    NSString *plistPath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];

    NSArray *args = @[
                      @"security",
                      @"cms", @"-D",
                      @"-i", path,
                      @"-o", plistPath
                      ];

    ShellResult *result = [ShellRunner xcrun:args timeout:10];

    if (!result.success) {
        NSLog(@"ERROR: security cms failed to parse profile:\n  %@", path);
        if (result.didTimeOut) {
            NSLog(@"ERROR: security cms timed out after %@ seconds", @(result.elapsed));
        } else {
            NSLog(@"=== STDERR ===");
            NSLog(@"%@", result.stderrStr);
        }
        return nil;
    }

    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfFile:plistPath
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
    if (!fileContents) {
        NSLog(@"ERROR: could not read the output file generate by security cms");
        NSLog(@"ERROR:           profile: %@", path);
        NSLog(@"ERROR:    exported plist: %@", plistPath);
        NSLog(@"ERROR: %@", error.localizedDescription);
    }

    return fileContents;
}

+ (NSDictionary *)dictionaryByExportingProfileWithSecurity:(NSString *) path {
    NSString *string = [MobileProfile stringByExportingProfileWithSecurity:path];
    if (!string) { return nil; }

    NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *plist;

    plist = [NSPropertyListSerialization propertyListWithData:data
                                                      options:NSPropertyListImmutable
                                                       format:nil
                                                        error:&error];

    if (!plist || plist.count == 0) {
        NSLog(@"ERROR: Could not parse plist to dictionary:");
        NSLog(@"=== PLIST BEGIN ===");
        NSLog(@"%@", string);
        NSLog(@"=== PLIST END ===");
        NSLog(@"ERROR: %@", [error localizedDescription]);
        return nil;
    }
    return plist;
}

+ (MobileProfile *)embeddedMobileProvision:(NSString *)appBundle
                                  identity:(CodesignIdentity *)identity
                                deviceUDID:(NSString *)deviceUDID {
    NSString *path = [appBundle stringByAppendingPathComponent:@"embedded.mobileprovision"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    NSDictionary *dictionary = [MobileProfile dictionaryByExportingProfileWithSecurity:path];

    if (!dictionary) { return nil; }

    MobileProfile *profile = [[MobileProfile alloc] initWithDictionary:dictionary path:path];

    if ([profile isExpired]) { return nil; }

    if (![profile.ProvisionedDevices containsObject:deviceUDID]) {
        return nil;
    } else {
        NSArray<Certificate *> *certificates = profile.DeveloperCertificates;
        BOOL match = NO;
        for(Certificate *cert in certificates) {
            if ([cert.shasum isEqualToString:identity.shasum]) {
                match = YES;
                break;
            }
        }

        if (match) {
            return profile;
        } else {
            return nil;
        }
    }
}

+ (NSArray<MobileProfile *> *)nonExpiredIOSProfiles {
    NSArray<NSString *> *paths = [MobileProfile arrayOfProfilePaths];
    if (!paths) { return nil; }

    NSMutableArray<MobileProfile *> *profiles;
    profiles = [NSMutableArray arrayWithCapacity:[paths count]];

    // The [NSMutableArray addObject:] is not thread safe.
    [paths enumerateObjectsWithOptions:NSEnumerationConcurrent
                            usingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *plist = [MobileProfile dictionaryByExportingProfileWithSecurity:path];
        if (plist) {
            MobileProfile *profile = [[MobileProfile alloc] initWithDictionary:plist
                                                           path:path];
            if ([profile isPlatformIOS] && ![profile isExpired]) {

                // This lock might negate any gains seen by concurrent execution.
                @synchronized (profiles) {
                    [profiles addObject:profile];
                }
            }
        }
    }];

    if ([profiles count] == 0) {
        return nil;
    }

    return [NSArray arrayWithArray:profiles];
}

+ (NSArray<MobileProfile *> *)rankedProfiles:(NSArray<MobileProfile *> *)mobileProfiles
                                withIdentity:(CodesignIdentity *)identity
                                  deviceUDID:(NSString *)deviceUDID
                               appBundlePath:(NSString *)appBundlePath {
    NSArray<MobileProfile *> *valid = mobileProfiles;

    if (!valid || valid.count == 0) { return nil; }

    Entitlements *appEntitlements;
    appEntitlements = [Entitlements entitlementsWithBundlePath:appBundlePath];

    if (!appEntitlements) { return nil; }

    NSMutableArray<MobileProfile *> *satisfyingProfiles;
    satisfyingProfiles = [NSMutableArray arrayWithCapacity:valid.count];

    // Lowest to highest
    NSComparator comparator = ^NSComparisonResult(MobileProfile *lhs,
                                                  MobileProfile *rhs) {
        if (lhs.rank > rhs.rank) { return (NSComparisonResult)NSOrderedDescending; }
        if (lhs.rank < rhs.rank) { return (NSComparisonResult)NSOrderedAscending; }
        return (NSComparisonResult)NSOrderedSame;
    };


    // The [NSMutableArray insertObject:atIndex:] is not thread safe.
    [mobileProfiles enumerateObjectsWithOptions:NSEnumerationConcurrent
                                     usingBlock:^(MobileProfile * _Nonnull profile,
                                                  NSUInteger idx, BOOL * _Nonnull stop) {
        if ([profile isValidForDeviceUDID:deviceUDID identity:identity]) {
            
            NSInteger score = [Entitlements rankByComparingProfileEntitlements:profile.Entitlements
                                                               appEntitlements:appEntitlements];
            // Reject any profiles that do meet the app requirements.
            if (score != ProfileDoesNotHaveRequiredKey) {
                profile.rank = score;
                NSRange range = NSMakeRange(0, satisfyingProfiles.count);
                NSUInteger insertIndex = [satisfyingProfiles indexOfObject:profile
                                                             inSortedRange:range
                                                                   options:NSBinarySearchingInsertionIndex
                                                           usingComparator:comparator];

                // This lock might negate any gains seen by concurrent execution.
                @synchronized (satisfyingProfiles) {
                    [satisfyingProfiles insertObject:profile atIndex:insertIndex];
                }
            }
        }
    }];
    
    return [NSArray arrayWithArray:satisfyingProfiles];
}

#pragma mark - Instance Methods

@synthesize info = _info;
@synthesize path = _path;
@synthesize certificates = _certificates;
@synthesize rank = _rank;

- (instancetype)initWithDictionary:(NSDictionary *)info
                              path:(NSString *)path {
    self = [super init];
    if (self) {
        _info = info;
        _path = path;
        _rank = 0;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"#<MobileProfile %@  <%@> expired: %@ rank: %@>",
            [[self Platform] componentsJoinedByString:@" "],
            [self AppIDName],
            [self isExpired] ? @"YES" : @"NO",
            @(self.rank)];
}

- (BOOL)isValidForDeviceUDID:(NSString *)deviceUDID
                    identity:(CodesignIdentity *)identity {
    if (![self.ProvisionedDevices containsObject:deviceUDID]) {
        return NO;
    } else {
        NSArray<Certificate *> *certificates = self.DeveloperCertificates;
        BOOL match = NO;
        for (Certificate *cert in certificates) {
            if ([cert.shasum isEqualToString:identity.shasum]) {
                match = YES;
                break;
            }
        }
        return match;
    }
}

- (id)objectForKeyedSubscript:(NSString *)key {
    return self.info[key] ?: nil;
}

- (NSString *)AppIDName {
    return self[@"AppIDName"];
}

- (NSArray<NSString *> *)ApplicationIdentifierPrefix {
    return (NSArray<NSString *> *)self[@"ApplicationIdentifierPrefix"];
}

- (NSArray<Certificate *> *)DeveloperCertificates {
    if (_certificates) { return _certificates; }

    NSArray<NSData *> *datum = (NSArray<NSData *> *)self[@"DeveloperCertificates"];

    NSMutableArray<Certificate *> *certs = [NSMutableArray arrayWithCapacity:[datum count]];
    Certificate *cert;

    for (NSData *data in datum) {
        cert = [Certificate certificateWithData:data];
        if (cert) {
            [certs addObject:cert];
        }
    }

    _certificates = [NSArray arrayWithArray:certs];
    return _certificates;
}

- (Entitlements *)Entitlements {
    NSDictionary *dictionary = (NSDictionary *)self[@"Entitlements"];
    return [Entitlements entitlementsWithDictionary:dictionary];
}

- (NSArray<NSString *> *)ProvisionedDevices {
    return (NSArray<NSString *> *)self[@"ProvisionedDevices"];
}

- (NSArray<NSString *> *)TeamIdentifier {
    return (NSArray<NSString *> *)self[@"TeamIdentifier"];
}

- (NSString *)UUID {
    return self[@"UUID"];
}

- (NSString *)TeamName {
    return self[@"TeamName"];
}

- (NSString *)Name {
    return self[@"Name"];
}

- (NSArray<NSString *> *)Platform {
    return (NSArray<NSString *> *)self[@"Platform"];
}

- (NSDate *)ExpirationDate {
    return (NSDate *)self[@"ExpirationDate"];
}

- (BOOL)isPlatformIOS {
    return [self.Platform containsObject:@"iOS"];
}

- (BOOL)isExpired {
    NSDate *expiration = self.ExpirationDate;
    return [expiration earlierDate:[NSDate date]] == expiration;
}

- (BOOL)containsDeviceUDID:(NSString *)deviceUDID {
    return [self.ProvisionedDevices containsObject:deviceUDID];
}

@end
