
#import "BundleResignerFactory.h"
#import "BundleResigner.h"
#import "MobileProfile.h"
#import "Entitlements.h"
#import "CodesignIdentity.h"

@interface BundleResignerFactory ()

@property(strong, readonly) NSArray<CodesignIdentity *> *identities;
@property(strong, readonly) NSArray<MobileProfile *> *mobileProfiles;

@end

@implementation BundleResignerFactory

@synthesize identities = _identities;
@synthesize mobileProfiles = _mobileProfiles;

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

+ (BundleResignerFactory *)shared {
    static BundleResignerFactory *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[BundleResignerFactory alloc] init];
    });
    return shared;
}

- (void)logExampleShellCommand {
    ConsoleWriteErr(@"$ CODE_SIGN_IDENTITY=\"iPhone Developer: Your Name (ABCDEF1234)\""
          "iOSDeviceManager < command >");
}

- (void)logValidSigningIdentities {
    ConsoleWriteErr(@"These are the valid signing identities that are available:");
    for(CodesignIdentity *identity in self.identities) {
        ConsoleWriteErr(@"   %@", identity);
    }
}

// TODO Ambiguous Matches - the name is not enough.
- (CodesignIdentity *)codesignIdentityMatchingString:(NSString *)string {

    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(CodesignIdentity *identity,
                                                                   NSDictionary *bindings) {
        return [identity.name isEqualToString:string] ||
        [identity.shasum isEqualToString:string];
    }];

    NSArray<CodesignIdentity *> *matches;
    matches = [self.identities filteredArrayUsingPredicate:predicate];

    if (matches.count == 0) { return nil; }

    CodesignIdentity *match = matches[0];

    if (matches.count == 1) { return match; }

    DDLogWarn(@"Ambiguous code sign identity detected:\n    %@", string);
    DDLogWarn(@"Found these possible matches:");
    DDLogWarn(@"    %@", [matches componentsJoinedByString:@"\n    "]);
    DDLogWarn(@"");
    DDLogWarn(@"Will try code signing with:\n    %@", match);
    DDLogWarn(@"");
    DDLogWarn(@"If code signing fails, trying using the SHASUM as the identifier");
    DDLogWarn(@"");
    DDLogWarn(@"Examples:");
    [matches enumerateObjectsUsingBlock:^(CodesignIdentity *identity, NSUInteger idx, BOOL *stop) {
        DDLogWarn(@"   CODE_SIGN_IDENTITY=%@ iOSDevice <command>", identity.shasum);
    }];

    return match;
}

- (nullable BundleResigner *)resignerWithBundlePath:(nonnull NSString *)bundlePath
                                         deviceUDID:(nonnull NSString *)deviceUDID
                                           identity:(nonnull CodesignIdentity *)identity {
    NSArray<MobileProfile *> *validProfiles = self.mobileProfiles;
    if (!validProfiles || validProfiles.count == 0) {
        ConsoleWriteErr(@"There are no valid profiles on your machine.");
        return nil;
    }

    MobileProfile *fromAppBundle;
    fromAppBundle = [MobileProfile embeddedMobileProvision:bundlePath
                                                  identity:identity
                                                deviceUDID:deviceUDID];
    MobileProfile *profile = nil;

    if (fromAppBundle) {
        profile = fromAppBundle;
    } else {
        NSArray<MobileProfile *> *rankedProfiles;
        rankedProfiles = [self rankedProfilesWithDeviceUDID:deviceUDID
                                            signingIdentity:identity
                                              appBundlePath:bundlePath];

        DDLogInfo(@"%@", rankedProfiles);

        if (!rankedProfiles || rankedProfiles.count == 0) {
            ConsoleWriteErr(@"Could not find any Provisioning Profiles suitable for resigning");
            ConsoleWriteErr(@"      identity: %@", identity);
            ConsoleWriteErr(@"   device UDID: %@", deviceUDID);
            ConsoleWriteErr(@"           app: %@", bundlePath);
            return nil;
        }

        profile = rankedProfiles[0];
    }

    Entitlements *originalEntitlements = [Entitlements entitlementsWithBundlePath:bundlePath];

    return [[BundleResigner alloc] initWithBundlePath:bundlePath
                                 originalEntitlements:originalEntitlements
                                             identity:identity
                                        mobileProfile:profile
                                           deviceUDID:deviceUDID];
}

- (nullable BundleResigner *)resignerWithBundlePath:(nonnull NSString *)bundlePath
                                         deviceUDID:(nonnull NSString *)deviceUDID
                              signingIdentityString:(nullable NSString *)signingIdentityOrNil {
    NSString *signingIdentityName = signingIdentityOrNil;
    if (!signingIdentityName) {
        signingIdentityName = [CodesignIdentity codeSignIdentityFromEnvironment];

        if (!signingIdentityName) {
            ConsoleWriteErr(@"You must provide a signing identity for this version of"
                  "iOSDeviceManager");
            ConsoleWriteErr(@"");
            [self logExampleShellCommand];
            ConsoleWriteErr(@"");
            [self logValidSigningIdentities];
            return nil;
        }
    }

    CodesignIdentity *identity = [self codesignIdentityMatchingString:signingIdentityName];

    if (!identity) {
        ConsoleWriteErr(@"The signing identity you provided is not valid:\n    %@",
              signingIdentityName);
        ConsoleWriteErr(@"");
        [self logValidSigningIdentities];
        return nil;
    }

    return [self resignerWithBundlePath:bundlePath
                             deviceUDID:deviceUDID
                               identity:identity];
}

- (nullable BundleResigner *)adHocResignerWithBundlePath:(NSString *)bundlePath
                                              deviceUDID:(NSString *)deviceUDID {
    return [[BundleResigner alloc] initWithBundlePath:bundlePath
                                             identity:nil
                                           deviceUDID:deviceUDID];
}

- (NSArray<CodesignIdentity *> *)identities {
    if (_identities) { return _identities; }

    _identities = [CodesignIdentity validIOSDeveloperIdentities];
    return _identities;
}

- (NSArray<MobileProfile *> *)mobileProfiles {
    if (_mobileProfiles) {return _mobileProfiles;}

    _mobileProfiles = [MobileProfile nonExpiredIOSProfiles];
    return _mobileProfiles;
}

- (NSArray<MobileProfile *> *)rankedProfilesWithDeviceUDID:(NSString *)deviceUDID
                                           signingIdentity:(CodesignIdentity *)identity
                                             appBundlePath:(NSString *)appBundlePath {
    return [MobileProfile rankedProfiles:self.mobileProfiles
                            withIdentity:identity
                              deviceUDID:deviceUDID
                           appBundlePath:appBundlePath];
}

@end
