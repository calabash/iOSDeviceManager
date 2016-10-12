#import "BundleResigner.h"
#import "CodesignIdentity.h"
#import "MobileProfile.h"
#import "Entitlements.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "BundleResignerFactory.h"

@interface BundleResigner ()

+ (NSDictionary *)pathsByRecursivelySearchingForThingsToSign:(NSString *)bundlePath;
+ (BOOL)removeExtendedAttributesFromFileAtPath:(NSString *)path;
+ (BOOL)removeExtendedAttributesFromFilesInDirectory:(NSString *)directory;

@property(copy, readonly) NSString *newAppIdentifier;
@property(copy, readonly) NSDictionary *signableAssets;
@property(copy, readonly) NSDictionary *infoPlist;


- (BOOL)resignAppPlugIns;
- (BOOL)resignPlugInAtPath:(NSString *)path;
- (BOOL)resignAppOrPluginBundleWithEntitlements:(BOOL)withEntitlements;
- (BOOL)resignLibrary:(NSString *)path;
- (BOOL)resignDylibsAndFrameworks;
- (NSString *)embeddedMobileProvisionPath;
- (BOOL)replaceEmbeddedMobileProvision;
- (NSString *)xcentPath;
- (BOOL)replaceOrCreateXcentFile;
- (NSString *)reverseDNSIdentifierByRemovingTeam:(Entitlements *)entitlements;
- (NSString *)executablePath;

@end

@implementation BundleResigner

+ (NSDictionary *)pathsByRecursivelySearchingForThingsToSign:(NSString *)bundlePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *bundleURL = [NSURL fileURLWithPath:bundlePath];

    NSDirectoryEnumerator *enumerator;
    enumerator = [fileManager enumeratorAtURL:bundleURL
                   includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                 errorHandler:^BOOL(NSURL *url, NSError *error) {
                                     if (error) {
                                         DDLogError(@"could not enumerate file in app "
                                               "bundle:\n    %@", url);
                                         DDLogError(@"%@", [error localizedDescription]);
                                     }
                                     return YES;
                                 }];

    NSMutableArray<NSString *> *libraries = [NSMutableArray array];
    NSMutableArray<NSString *> *plugIns = [NSMutableArray array];
    for (NSURL *fileURL in enumerator) {
        NSString *filename;
        [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];

        NSString *extension = [filename pathExtension];

        NSNumber *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        if ([isDirectory boolValue]) {
            if ([extension isEqualToString:@"framework"]) {
                [libraries addObject:[fileURL path]];
                [enumerator skipDescendants];
            } else if ([extension isEqualToString:@"appex"]) {
                [plugIns addObject:[fileURL path]];
                [enumerator skipDescendants];
            } else if ([extension isEqualToString:@"xctest"]) {
                [plugIns addObject:[fileURL path]];
                [enumerator skipDescendants];
            }
        } else if ([extension isEqualToString:@"dylib"]) {
            [libraries addObject:[fileURL path]];
        }
    }

    return @{@"plug-ins": plugIns, @"libraries": libraries};
}

+ (BOOL)removeExtendedAttributesFromFileAtPath:(NSString *)path {
    NSArray<NSString *> *args = @[@"xattr", @"-c", path];

    ShellResult *result = [ShellRunner xcrun:args timeout:1];
    if (!result.success) {
        DDLogError(@"Could not remove attributes from file:\n    %@", path);
        DDLogError(@"with command:\n    %@", result.command);
        if (result.didTimeOut) {
            DDLogError(@"timed out after %@ seconds", @(result.elapsed));
        } else {
            DDLogError(@" === STDERR ===");
            DDLogError(@"%@", result.stderrStr);
        }
        return NO;
    }
    return YES;
}

// Unused - please keep this around for testing.
+ (BOOL)removeExtendedAttributesFromFilesInDirectory:(NSString *)directory {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *bundleURL = [NSURL fileURLWithPath:directory];

    NSDirectoryEnumerator *enumerator;
    enumerator = [fileManager enumeratorAtURL:bundleURL
                   includingPropertiesForKeys:@[NSURLNameKey, NSURLIsRegularFileKey]
                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                 errorHandler:^BOOL(NSURL *url, NSError *error) {
                                     if (error) {
                                         DDLogError(@"could not enumerate file in app "
                                               "bundle:\n    %@", url);
                                         DDLogError(@"%@", [error localizedDescription]);
                                     }
                                     return YES;
                                 }];

    BOOL success = YES;
    for (NSURL *fileURL in enumerator) {
        NSString *filename;
        [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];

        NSNumber *isRegularFile;
        [fileURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:nil];

        NSString *path;
        if (isRegularFile) {
            path = [fileURL path];
            success = [BundleResigner removeExtendedAttributesFromFileAtPath:path];
            if (!success) {
                break;
            }
        }
    }

    return success;
}

#pragma mark - Instance Methods

@synthesize newAppIdentifier = _newAppIdentifier;
@synthesize signableAssets = _signableAssets;
@synthesize infoPlist = _infoPlist;
@synthesize deviceUDID = _deviceUDID;

- (instancetype)initWithBundlePath:(NSString *)bundlePath
              originalEntitlements:(Entitlements *)originalEntitlements
                          identity:(CodesignIdentity *)identity
                     mobileProfile:(MobileProfile *)mobileProfile
                        deviceUDID:(NSString *)deviceUDID {
    self = [super init];
    if (self) {
        _bundlePath = bundlePath;
        _originalEntitlements = originalEntitlements;
        _identity = identity;
        _mobileProfile = mobileProfile;
        _deviceUDID = deviceUDID;
    }
    return self;
}

- (instancetype)initWithBundlePath:(NSString *)bundlePath
                          identity:(CodesignIdentity *)identity
                        deviceUDID:(NSString *)deviceUDID {
    self = [super init];
    if (self) {
        _bundlePath = bundlePath;
        _originalEntitlements = nil;
        if (identity) {
            _identity = identity;
        } else {
            _identity = [CodesignIdentity adHoc];
        }
        _mobileProfile = nil;
        _deviceUDID = deviceUDID;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<BundleResigner: %@\n    %@\n    %@\n    %@\n>",
            [self.bundlePath lastPathComponent],
            self.originalEntitlements,
            self.identity,
            self.mobileProfile];
}

- (BOOL)resign {
    return
    [self replaceEmbeddedMobileProvision] &&
    [self replaceOrCreateXcentFile] &&
    [self resignAppPlugIns] &&
    [self resignDylibsAndFrameworks] &&
    [self resignAppOrPluginBundleWithEntitlements:YES] &&
    [self validateBundleSignature];
}

- (BOOL)resignSimBundle {
    return
    [self resignAppPlugIns] &&
    [self resignDylibsAndFrameworks] &&
    [self resignAppOrPluginBundleWithEntitlements:NO] &&
    [self validateBundleSignature];
}

- (BOOL)resignAppOrPluginBundleWithEntitlements:(BOOL)withEntitlements {
    NSArray<NSString *> *args;
    if (withEntitlements) {
        args = @[@"codesign",
                 @"--force",
                 @"--sign", self.identity.shasum,
                 @"--verbose=4",
                 @"--entitlements", [self xcentPath],
                 self.bundlePath];

    } else {
        args = @[@"codesign",
                 @"--force",
                 @"--sign", self.identity.shasum,
                 @"--verbose=4",
                 @"--deep",
                 @"--timestamp=none",
                 self.bundlePath];
    }

    ShellResult *result = [ShellRunner xcrun:args timeout:10];
    if (!result.success) {
        DDLogError(@"Could not resign app bundle at path:\n    %@", self.bundlePath);
        DDLogError(@"with command:\n    %@", result.command);
        if (result.didTimeOut) {
            DDLogError(@"timed out after %@ seconds", @(result.elapsed));
        } else {
            DDLogError(@"=== STDERR ===");
            DDLogError(@"%@", result.stderrStr);
        }
        return NO;
    }

    return YES;
}

- (BOOL)validateBundleSignature {
    NSArray<NSString *> *args = @[@"codesign",
                                  @"--verbose=4",
                                  @"--verify",
                                  [self executablePath]];
    ShellResult *result = [ShellRunner xcrun:args timeout:10];

    if (!result.success) {
        DDLogError(@"Could not resign app bundle at path:\n    %@", self.bundlePath);
        DDLogError(@"with command:\n    %@", result.command);
        if (result.didTimeOut) {
            DDLogError(@"timed out after %@ seconds", @(result.elapsed));
        } else {
            DDLogError(@"=== STDERR ===");
            DDLogError(@"%@", result.stderrStr);
        }
        return NO;
    }

    return YES;
}

- (BOOL)resignAppPlugIns {
    NSArray *plugIns = self.signableAssets[@"plug-ins"];

    BOOL allPlugInsSigned = YES;
    for (NSString *path in plugIns) {
        BOOL success = [self resignPlugInAtPath:path];
        if (!success) {
            allPlugInsSigned = NO;
            break;
        }
    }

    return allPlugInsSigned;
}

- (BOOL)resignPlugInAtPath:(NSString *)path {
    BundleResigner *resigner;
    resigner = [[BundleResignerFactory shared] resignerWithBundlePath:path
                                                           deviceUDID:self.deviceUDID
                                                             identity:self.identity];
    if (!resigner) {
        return NO;
    } else {
        return [resigner resign];
    }
}

- (BOOL)resignDylibsAndFrameworks {
    NSArray *libraries = self.signableAssets[@"libraries"];

    BOOL allLibrariesSigned = YES;
    for (NSString *path in libraries) {
        BOOL success = [self resignLibrary:path];
        if (!success) {
            allLibrariesSigned = NO;
            break;
        }
    }

    return allLibrariesSigned;
}

- (BOOL)resignLibrary:(NSString *)path {
    NSArray<NSString *> *args = @[@"codesign",
                                  @"--force",
                                  @"--sign", self.identity.shasum,
                                  @"--verbose=4",
                                  @"--deep",
                                  path];
    ShellResult *result = [ShellRunner xcrun:args timeout:10];
    if (!result.success) {
        DDLogError(@"Could not resign library at path:\n    %@", path);
        DDLogError(@"with command:\n    %@", result.command);
        if (result.didTimeOut) {
            DDLogError(@"timed out after %@ seconds", @(result.elapsed));
        } else {
            DDLogError(@"=== STDERR ===");
            DDLogError(@"%@", result.stderrStr);
        }
        return NO;
    }
    return YES;
}

- (NSString *)embeddedMobileProvisionPath {
    return [self.bundlePath stringByAppendingPathComponent:@"embedded.mobileprovision"];
}

- (BOOL)replaceEmbeddedMobileProvision {
    NSString *targetPath = [self embeddedMobileProvisionPath];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *sourcePath = self.mobileProfile.path;


    // Resigning with the original embedded.mobileprovision
    if ([targetPath isEqualToString:sourcePath]) {
        DDLogInfo(@"Resigning with original embedded.mobileprovision");
        return YES;
    }

    NSError *error = nil;
    if ([manager fileExistsAtPath:targetPath]) {
        if (![manager removeItemAtPath:targetPath
                                 error:&error]) {
            DDLogError(@"Could not remove old embedded.mobileprovision:\n    %@",
                  targetPath);
            DDLogError(@"%@", [error localizedDescription]);
            return NO;
        }
    }

    if (![manager copyItemAtPath:sourcePath
                          toPath:targetPath
                           error:&error]) {
        DDLogError(@"Could not copy new embedded.mobileprovision:");
        DDLogError(@"    source: %@", sourcePath);
        DDLogError(@"    target: %@", targetPath);
        DDLogError(@"%@", [error localizedDescription]);
        return NO;
    }

    NSDictionary *permissions = @{NSFilePosixPermissions : @0666};

    if (![manager setAttributes:permissions ofItemAtPath:targetPath error:&error]) {
        DDLogError(@"Could not change permissions of . to path:\n %@",    targetPath);
        DDLogError(@"%@", [error localizedDescription]);
        return NO;
    }

    // On macOS Sierra, resource forks and extended attributes are being created when
    // files are copied by NSFileManager.  This cannot be present during code signing.
    //
    // Error:
    // resource fork, Finder information, or similar detritus not allowed
    //
    // The offending file is _usually_ the new embedded.mobileprovision.
    //
    // It might be safer to remove all extended attributes before signing, but it is
    // very very slow.
    //
    // To give an idea of the difference:
    //
    // * All files: 40 seconds to sign the DeviceAgent-Runner 3 times
    // * mobileprovision: 7 seconds to sign the DeviceAgent-Runner 3 times
    [BundleResigner removeExtendedAttributesFromFileAtPath:targetPath];

    return YES;
}

- (NSString *)xcentPath {
    NSString *executableName = self.infoPlist[@"CFBundleExecutable"];
    NSString *fileName = [NSString stringWithFormat:@"%@.xcent", executableName];
    return [self.bundlePath stringByAppendingPathComponent:fileName];
}

- (BOOL)replaceOrCreateXcentFile {
    NSFileManager *manager = [NSFileManager defaultManager];

    NSError *error = nil;

    NSString *path = [self xcentPath];
    if ([manager fileExistsAtPath:path]) {
        if (![manager removeItemAtPath:path error:&error]) {
            // Log failures and wait to see if this blows up later.
            DDLogWarn(@"Could not remove .xcent at path:\n    %@", path);
            DDLogWarn(@"     %@", [error localizedDescription]);
        }
    }

    Entitlements *olds = self.mobileProfile.Entitlements;
    Entitlements *news = [olds entitlementsByReplacingApplicationIdentifier:self.newAppIdentifier];

    if (![news writeToFile:[self xcentPath]]) {
        DDLogError(@"Could not write .xcent to path:\n    %@", path);
        return NO;
    }

    NSDictionary *permissions = @{NSFilePosixPermissions : @0666};

    if (![manager setAttributes:permissions ofItemAtPath:path error:&error]) {
        DDLogError(@"Could not change permissions of .xcent at path:\n    %@", path);
        DDLogError(@"%@", [error localizedDescription]);
        return NO;
    }

    return YES;
}

- (NSString *)reverseDNSIdentifierByRemovingTeam:(Entitlements *)entitlements {
    NSString *appIdentifier = entitlements[@"application-identifier"];
    NSString *appIdentifierPrefix;
    appIdentifierPrefix = [NSString stringWithFormat:@"%@.",
                           entitlements[@"com.apple.developer.team-identifier"]];
    return [appIdentifier stringByReplacingOccurrencesOfString:appIdentifierPrefix
                                                    withString:@""];
}

- (NSString *)executablePath {
    NSString *executableName = self.infoPlist[@"CFBundleExecutable"];
    return [self.bundlePath stringByAppendingPathComponent:executableName];
}

- (NSString *)newAppIdentifier {
    if (_newAppIdentifier) { return _newAppIdentifier; }

    Entitlements *new = self.mobileProfile.Entitlements;
    NSString *newReverseDNS = [self reverseDNSIdentifierByRemovingTeam:new];

    Entitlements *old = self.originalEntitlements;
    NSString *oldReverseDNS = [self reverseDNSIdentifierByRemovingTeam:old];

    NSString *newAppIdentifier = self.mobileProfile.Entitlements[@"application-identifier"];
    NSString *newAppIdentifierPrefix = self.mobileProfile.ApplicationIdentifierPrefix[0];

    if ([newReverseDNS isEqualToString:@"*"]) {
        _newAppIdentifier = [newAppIdentifierPrefix stringByAppendingFormat:@".%@", oldReverseDNS];
    } else {
        _newAppIdentifier = newAppIdentifier;
    }

    return _newAppIdentifier;
}

- (NSDictionary *)signableAssets {
    if (_signableAssets) { return _signableAssets; }

    _signableAssets =
    [BundleResigner pathsByRecursivelySearchingForThingsToSign:self.bundlePath];
    return _signableAssets;
}

- (NSDictionary *)infoPlist {
    if (_infoPlist) { return _infoPlist; }
    NSString *path = [self.bundlePath stringByAppendingPathComponent:@"Info.plist"];
    _infoPlist = [NSDictionary dictionaryWithContentsOfFile:path];
    return _infoPlist;
}

@end
