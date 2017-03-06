
#import "CodesignIdentity.h"
#import "ExceptionUtils.h"
#import "MobileProfile.h"
#import "ConsoleWriter.h"
#import "Entitlements.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "Certificate.h"
#import "Entitlement.h"
#import "JSONUtils.h"

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

+ (MobileProfile *)withPath:(NSString *)profilePath {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:profilePath]) {
        ConsoleWriteErr(@"No profile file at path: %@", profilePath);
        return nil;
    }

    NSDictionary *dictionary = [MobileProfile dictionaryByExportingProfileWithSecurity:profilePath];

    if (!dictionary) {
        ConsoleWriteErr(@"Unable to create dictionary for profile at: %@", profilePath);
        return nil;
    }

    MobileProfile *profile = [[MobileProfile alloc] initWithDictionary:dictionary path:profilePath];

    if ([profile isExpired]) {
        ConsoleWriteErr(@"Profile expired at path: %@", profilePath);
        return nil;
    }

    return profile;
}

/*
    Profile "Auto-detection" with specified CodesignIdentity
*/
+ (MobileProfile *)bestMatchProfileForApplication:(Application *)app
                                           device:(Device *)device
                                 codesignIdentity:(CodesignIdentity *)codesignID {
    LogInfo(@"Using signing identity %@ to select best match profile.", codesignID);

    NSArray<MobileProfile *> *profiles = [MobileProfile rankedProfiles:[self nonExpiredIOSProfiles]
                                                          withIdentity:codesignID
                                                            deviceUDID:device.uuid
                                                         appBundlePath:app.path];

    MobileProfile *match = profiles.count ? profiles[0] : nil;
    LogInfo(@"Selected profile %@ for device %@ app %@", match, device.uuid, app.bundleID);
    return match;
}

/*
    Profile "Auto-detection"
 */
+ (MobileProfile *)bestMatchProfileForApplication:(Application *)app device:(Device *)device {
    CodesignIdentity *identity = [CodesignIdentity identityForAppBundle:app.path
                                                               deviceId:device.uuid];
    CBXAssert(identity,
             @"Unable to find appropriate codesign identity for device %@ / app %@ combo",
             device.uuid,
             app.bundleID);

    LogInfo(@"Using signing identity %@ to select best match profile.", identity);

    NSArray<MobileProfile *> *profiles = [MobileProfile rankedProfiles:[self nonExpiredIOSProfiles]
                                                          withIdentity:identity
                                                            deviceUDID:device.uuid
                                                         appBundlePath:app.path];

    MobileProfile *match = profiles.count ? profiles[0] : nil;
    LogInfo(@"Selected profile %@ for device %@ app %@", match, device.uuid, app.bundleID);
    return match;
}

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
        ConsoleWriteErr(@"Could not find any mobileprovision files in:\n"
              "  %@", directory);
        ConsoleWriteErr(@"%@", [error localizedDescription]);
        return nil;
    } else if (contents.count == 0) {
        ConsoleWriteErr(@"Could not find any mobileprovision files in:\n"
              "  %@", directory);
        ConsoleWriteErr(@"There was no error, but there were no files in that directory");
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
        ConsoleWriteErr(@"security cms failed to parse profile:\n  %@", path);
        if (result.didTimeOut) {
            ConsoleWriteErr(@"security cms timed out after %@ seconds", @(result.elapsed));
        } else {
            ConsoleWriteErr(@"=== STDERR ===");
            ConsoleWriteErr(@"%@", result.stderrStr);
        }
        return nil;
    }

    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfFile:plistPath
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];
    if (!fileContents) {
        ConsoleWriteErr(@"could not read the output file generate by security cms");
        ConsoleWriteErr(@"          profile: %@", path);
        ConsoleWriteErr(@"   exported plist: %@", plistPath);
        ConsoleWriteErr(@"%@", error.localizedDescription);
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
        ConsoleWriteErr(@"Could not parse plist to dictionary:");
        ConsoleWriteErr(@"=== PLIST BEGIN ===");
        ConsoleWriteErr(@"%@", string);
        ConsoleWriteErr(@"=== PLIST END ===");
        ConsoleWriteErr(@"%@", [error localizedDescription]);
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

    if (![profile.provisionedDevices containsObject:deviceUDID]) {
        return nil;
    } else {
        NSArray<Certificate *> *certificates = profile.developerCertificates;
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
    if (!paths) {
        ConsoleWriteErr(@"Error getting list of non-expired profiles;");
        return nil;
    }

    NSMutableArray<MobileProfile *> *profiles;
    profiles = [NSMutableArray arrayWithCapacity:[paths count]];

    // The [NSMutableArray addObject:] is not thread safe.
    [paths enumerateObjectsWithOptions:NSEnumerationConcurrent
                            usingBlock:^(NSString * _Nonnull path,
                                         NSUInteger idx,
                                         BOOL * _Nonnull stop) {
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

/*
    Ranked by most-preferred first
 */
+ (NSArray<MobileProfile *> *)rankedProfiles:(NSArray<MobileProfile *> *)mobileProfiles
                                withIdentity:(CodesignIdentity *)identity
                                  deviceUDID:(NSString *)deviceUDID
                               appBundlePath:(NSString *)appBundlePath {
    NSParameterAssert(mobileProfiles);
    NSParameterAssert(mobileProfiles.count);

    NSArray<MobileProfile *> *valid = mobileProfiles;

    Entitlements *appEntitlements;
    appEntitlements = [Entitlements entitlementsWithBundlePath:appBundlePath];

    if (!appEntitlements) {
        ConsoleWriteErr(@"App %@ has no entitlements, refusing to rank profiles.", appBundlePath);
        return nil;
    }

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
            NSInteger score = [Entitlements rankByComparingProfileEntitlements:profile.entitlements
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
            [[self platform] componentsJoinedByString:@" "],
            [self appIDName],
            [self isExpired] ? @"YES" : @"NO",
            @(self.rank)];
}

- (BOOL)isValidForDeviceUDID:(NSString *)deviceUDID
                    identity:(CodesignIdentity *)identity {
    if (![self.provisionedDevices containsObject:deviceUDID]) {
        return NO;
    } else {
        NSArray<Certificate *> *certificates = self.developerCertificates;
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

- (NSString *)appIDName {
    return self[@"AppIDName"];
}

- (NSArray<NSString *> *)applicationIdentifierPrefix {
    return (NSArray<NSString *> *)self[@"ApplicationIdentifierPrefix"];
}

- (NSArray<Certificate *> *)developerCertificates {
    if (!_certificates.count) {
        NSArray<NSData *> *data = (NSArray<NSData *> *)self[@"DeveloperCertificates"];

        NSMutableArray<Certificate *> *certs = [NSMutableArray arrayWithCapacity:[data count]];
        Certificate *cert;

        //'datum' is singular :)
        for (NSData *datum in data) {
            cert = [Certificate certificateWithData:datum];
            if (cert) {
                [certs addObject:cert];
            }
        }

        _certificates = [NSArray arrayWithArray:certs];
    };
    return _certificates;
}

- (CodesignIdentity *)findValidIdentity {
    NSArray *validCodesignIdentities = [CodesignIdentity validIOSDeveloperIdentities];
    for (Certificate *cert in self.developerCertificates) {
        CodesignIdentity *identity = [[CodesignIdentity alloc] initWithShasum:cert.shasum name:cert.commonName];
        if ([validCodesignIdentities containsObject:identity]) {
            return identity;
        }
    }
    return nil;
}

- (Entitlements *)entitlements {
    NSDictionary *dictionary = (NSDictionary *)self[@"Entitlements"];
    return [Entitlements entitlementsWithDictionary:dictionary];
}

- (NSArray<NSString *> *)provisionedDevices {
    return (NSArray<NSString *> *)self[@"ProvisionedDevices"];
}

- (NSArray<NSString *> *)teamIdentifier {
    return (NSArray<NSString *> *)self[@"TeamIdentifier"];
}

- (NSString *)uuid {
    return self[@"UUID"];
}

- (NSString *)teamName {
    return self[@"TeamName"];
}

- (NSString *)name {
    return self[@"Name"];
}

- (NSArray<NSString *> *)platform {
    return (NSArray<NSString *> *)self[@"Platform"];
}

- (NSDate *)expirationDate {
    return (NSDate *)self[@"ExpirationDate"];
}

- (BOOL)isPlatformIOS {
    return [self.platform containsObject:@"iOS"];
}

- (BOOL)isExpired {
    NSDate *expiration = self.expirationDate;
    return [expiration earlierDate:[NSDate date]] == expiration;
}

- (BOOL)containsDeviceUDID:(NSString *)deviceUDID {
    return [self.provisionedDevices containsObject:deviceUDID];
}

@end
