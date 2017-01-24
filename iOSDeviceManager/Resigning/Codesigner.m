
#import "iOSDeviceManagementCommand.h"
#import "BundleResignerFactory.h"
#import "BundleResigner.h"
#import "ConsoleWriter.h"
#import "Entitlements.h"
#import "Certificate.h"
#import "ShellRunner.h"
#import "DeviceUtils.h"
#import "StringUtils.h"
#import "ShellResult.h"
#import "Codesigner.h"
#import "FileUtils.h"

static NSString *const IDMCodeSignErrorDomain = @"sh.calaba.iOSDeviceManger";

@interface Codesigner ()
@end

@implementation Codesigner

+ (void)resignApplication:(Application *)app
  withProvisioningProfile:(MobileProfile *)profile {
    [self resignApplication:app
    withProvisioningProfile:profile
          resourcesToInject:nil];
}

+ (void)resignApplication:(Application *)app
  withProvisioningProfile:(MobileProfile *)profile
        resourcesToInject:(NSArray<NSString *> *)resourcePaths {
    [self prepareResign:app];
    [self resignAppDir:app.path
               baseDir:app.baseDir
   provisioningProfile:profile
     resourcesToInject:resourcePaths];
}

+ (void)resignApplication:(Application *)app
              forProfiles:(NSArray <MobileProfile *> *)profiles
        resourcesToInject:(NSArray<NSString *> *)resourcePaths
         resigningHandler:(appResigningCompleteBlock)handler {
    [self prepareResign:app];
    for (MobileProfile *profile in profiles) {
        [self resignAppDir:app.path
                   baseDir:app.baseDir
       provisioningProfile:profile
         resourcesToInject:resourcePaths];
        handler(app);
    }
}


/*
 There are two types of resignables: Objects and Bundles.
 
 Objects include .dylibs and .frameworks
 
 Bundles include .app, .appex, and .xctest.
 
 The main difference is that bundles require consideration of Entitlements
 whereas objects simply need to have the codesign identity applied to their
 signature segment.
 */

/**
 Resigns a .framework or .dylib
 */
+ (void)resignObject:(NSString *)pathToObject
    codesignIdentity:(NSString *)codesignID {
    NSString *originalSigningID = [self getObjectSigningID:pathToObject];
    NSArray<NSString *> *args = @[@"codesign",
                                  @"--force",
                                  @"--sign", codesignID,
                                  @"--verbose=4",
                                  @"--deep",
                                  pathToObject];
    ShellResult *result = [ShellRunner xcrun:args timeout:10];
    BOOL success = result.success;
    NSAssert(success, @"Error codesigning %@: %@", pathToObject, result.stderrStr);
    LogInfo(@"Codesigned %@: '%@' => '%@'",
            [pathToObject lastPathComponent],
            originalSigningID,
            [self getObjectSigningID:pathToObject]);
}

/**
 Resigns a .app, .appex, or .xctest bundle.
 */
+ (void)resignBundle:(NSString *)pathToBundle
    bundleExecutable:(NSString *)bundleExecutableFile
 appEntitlementsFile:(NSString *)pathToEntitlementsFile
    codesignIdentity:(NSString *)codesignID {
    NSString *originalSigningID = [self getObjectSigningID:pathToBundle];
    NSArray<NSString *> *args = @[@"codesign",
                                  @"--force",
                                  @"--sign", codesignID,
                                  @"--vv", bundleExecutableFile,
                                  @"--entitlements", pathToEntitlementsFile,
                                  pathToBundle];
    ShellResult *result = [ShellRunner xcrun:args timeout:10];
    BOOL success = result.success;
    NSAssert(success, @"Error codesigning %@: %@", pathToBundle, result.stderrStr);
    LogInfo(@"Codesigned %@: '%@' => '%@'",
            [pathToBundle lastPathComponent],
            originalSigningID,
            [self getObjectSigningID:pathToBundle]);
}

+ (BOOL)isWildcardAppId:(NSString *)appId {
    return [appId isEqualToString:@"*"];
}

+ (NSString *)getOldBundleId:(Entitlements *)oldEntitlements
                   infoPlist:(NSDictionary *)infoPlist {
    if ([oldEntitlements applicationIdentifier] && oldEntitlements[@"com.apple.developer.team-identifier"]) {
        return [oldEntitlements applicationIdentifierWithoutPrefix];
    } else {
        return infoPlist[@"CFBundleIdentifier"];
    }
}

+ (void)injectResources:(NSArray <NSString *> *)resourcePaths
             intoAppDir:(NSString *)appDir
       codesignIdentity:(NSString *)codesignIdentity
                baseDir:(NSString *)baseDir {
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSError *e = nil;
    
    for (NSString *resourcePath in resourcePaths) {
        NSAssert([mgr fileExistsAtPath:resourcePath],
                 @"Failed to inject resources: file '%@' does not exist!",
                 resourcePath);
        NSString *targetFile = [appDir stringByAppendingPathComponent:[resourcePath lastPathComponent]];
        [mgr copyItemAtPath:resourcePath
                     toPath:targetFile
                      error:&e];
        NSAssert(e == nil, @"Error injecting resource: %@", e);
        if ([FileUtils isDylibOrFramework:targetFile]) {
            [self resignObject:targetFile
              codesignIdentity:codesignIdentity];
            NSAssert(e == nil, @"Error resigning object: %@", e);
        }
    }
}

+ (NSString *)codesignInfo:(NSString *)objectPath {
    NSArray<NSString *> *args = @[@"codesign",
                                  @"-d",
                                  @"-vvv",
                                  objectPath];
    ShellResult *result = [ShellRunner xcrun:args timeout:10];
    
    NSAssert(result.success, @"Could not extract codesign info from %@. Stderr: %@. Time elapsed: %@",
             objectPath,
             result.stderrStr,
             @(result.elapsed));
    
    /*
        Apple felt it made more sense to print everything to stderr <(*.0)>
     */
    return result.stderrStr;
}

+ (NSString *)getObjectSigningID:(NSString *)object {
    if ([self isCodesigned:object]) {
        NSString *codesignInfo = [self codesignInfo:object];
        return [[codesignInfo matching:@"TeamIdentifier=([A-Z\\d]+)"] lastObject];
    }
    return nil;
}

+ (BOOL)isCodesigned:(NSString *)objectPath {
    NSString *info = [self codesignInfo:objectPath];
    return ![info containsString:@"object is not signed at all"];
}

+ (BOOL)shouldResign:(NSString *)objectPath
           inBaseDir:(NSString *)baseDir {
    NSString *baseSigningID = [self getObjectSigningID:baseDir];
    NSString *objectSigningID = [self getObjectSigningID:baseDir];
    return ![self isCodesigned:baseDir] ||
            baseSigningID == nil ||
            [baseSigningID isEqualToString:objectSigningID] ||
            [baseSigningID isEqualToString:@"not set"];
}

+ (BOOL)isResignableBundle:(NSString *)bundlePath {
    return [bundlePath hasSuffix:@".xctest"] ||
            [bundlePath hasSuffix:@".appex"];
}

+ (void)resignAppDir:(NSString *)appDir
             baseDir:(NSString *)baseDir
 provisioningProfile:(MobileProfile *)profile
   resourcesToInject:(NSArray<NSString *> *)resourcesToInject {
    NSString *mobileProfileUUID = [profile uuid];
    NSArray *prefixes = [profile applicationIdentifierPrefix];
    if (prefixes.count == 0) {
        ConsoleWriteErr(@"Profile has no application identifier prefixes: %@ [%@]",
                       [profile name],
                       mobileProfileUUID);
    }
    NSString *appIDPrefix = prefixes[0];
    
    NSString *codesignIdentity = [profile findValidIdentity].shasum;
    NSAssert(codesignIdentity, @"Unable to find valid codesign identity from profile %@", profile.name);
    
    Entitlements *newEntitlements = [profile entitlements];
    Entitlements *oldEntitlements = [Entitlements entitlementsWithBundlePath:appDir];
    
    NSString *mobileProfileAppID = [newEntitlements applicationIdentifierWithoutPrefix];
    NSString *infoPlistPath = [appDir joinPath:@"Info.plist"];
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSAssert([mgr fileExistsAtPath:infoPlistPath], @"No Info.plist found for bundle: %@", appDir);

    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSString *oldBundleID = [self getOldBundleId:oldEntitlements infoPlist:infoPlist];
    NSString *finalAppIdentifier = [self isWildcardAppId:mobileProfileAppID] ?
                                    [NSString stringWithFormat:@"%@.%@", appIDPrefix, oldBundleID] :
                                    [newEntitlements applicationIdentifier];
    
    LogInfo(@"Resigning bundle %@ with profile %@", appDir, [profile name]);
    
    NSString *appGroupKey = @"com.apple.security.application-groups";
    NSArray *appGroups = oldEntitlements[appGroupKey] ?: @[];
    NSArray *ourAppGroups = newEntitlements[appGroupKey] ?: @[];
    
    
    //Trim to equal length
    if (appGroups.count <= ourAppGroups.count) {
        ourAppGroups = [ourAppGroups subarrayWithRange:NSMakeRange(0, appGroups.count)];
    } else {
        //TODO: handle --force option
        //TODO: Can we relax this constraint?
        //i.e. appGroups = [appGroups subarrayWithRange:NSMakeRange(0, ourAppGroups.count)];
        NSAssert(NO,
                 @"Application has more app groups then %@ supports",
                 [profile name]);
    }
    
    //Randomly assign a mapping
    NSDictionary *appGroupMap = [NSDictionary dictionaryWithObjects:ourAppGroups
                                                            forKeys:appGroups];
    
    NSDictionary *entitlementsMap = @{
                                      @"AppGroupIDs" : appGroupMap,
                                      @"AllAppGroupIDs" : ourAppGroups ?: @[]
                                      };
    
    NSString *entitlementsMapFile = [appDir joinPath:@"XTCEntitlementsMeta.plist"];
    BOOL success = [entitlementsMap writeToFile:entitlementsMapFile
                                     atomically:YES];
    NSAssert(success, @"Unable to write EntitlementsMeta to application.");
    
    [self injectResources:resourcesToInject
               intoAppDir:appDir
         codesignIdentity:codesignIdentity
                  baseDir:baseDir];
    
    NSString *embeddedMobileProvision = [appDir joinPath:@"embedded.mobileprovision"];
    if ([mgr fileExistsAtPath:embeddedMobileProvision]) {
        if ([mgr removeItemAtPath:embeddedMobileProvision error:nil]) {
            LogInfo(@"Removed embedded.mobileprovision from %@", appDir);
        } else {
            //I do not think this will block resigning so we don't need to NSAssert - CF
            ConsoleWriteErr(@"Unable to remove embedded.mobileprovision from app dir %@", appDir);
        }
    }
    
    //Sanity check
    NSAssert(infoPlist[@"CFBundleIdentifier"] != nil, @"Bundle identifier is nil! Plist: %@", infoPlist);
    
    NSString *bundleExec = infoPlist[@"CFBundleExecutable"];
    NSString *bundleExecPath = [appDir joinPath:bundleExec];
    NSString *appDirName = [appDir lastPathComponent];
    
    //the 'appId' is the name of the app dir minus the `.app` extension
    NSString *appId = [appDirName subsFrom:0 length:appDirName.length - @".app".length];
    NSString *xcentFilename = [appId plus:@".xcent"];
    NSString *appEntitlementsFile = [appDir joinPath:xcentFilename];
    Entitlements *finalEntitlements = [newEntitlements entitlementsByReplacingApplicationIdentifier:finalAppIdentifier];
    NSString *newTeamId = finalEntitlements[@"com.apple.developer.team-identifier"];
    
    NSAssert([mgr fileExistsAtPath:bundleExecPath], @"Bundle executable %@ does not exist!", bundleExecPath);
    LogInfo(@"Original entitlements:");
    LogInfo(@"%@", oldEntitlements);
    LogInfo(@"New Entitlements");
    LogInfo(@"%@", newEntitlements);
    LogInfo(@"Resigning to new teamID: %@", newTeamId);
    
    [FileUtils fileSeq:appDir handler:^(NSString *filepath) {
        if ([FileUtils isDylibOrFramework:filepath] && [self shouldResign:filepath inBaseDir:appDir]) {
            [self resignObject:filepath
              codesignIdentity:codesignIdentity];
        }
    }];
    
    /* 
     Codesign every .xctest and .appex bundle inside of Plugins dir
    
     Note that we recurse here instead of calling `resign-bundle-object` directly,
     because we want to respect the entitlements of the sub-bundles which may differ
     from the parent.
    
     Note also that the objects resigned above won't be resigned again because
    `+ (BOOL)shouldResign` should return false once they've already been resigned.
    */
    
    NSString *pluginsPath = [appDir joinPath:@"Plugins"];
    [FileUtils fileSeq:pluginsPath handler:^(NSString *filepath) {
        if ([self isResignableBundle:filepath] &&
            [self shouldResign:filepath inBaseDir:baseDir]) {
            [self resignAppDir:filepath
                       baseDir:baseDir
           provisioningProfile:profile
             resourcesToInject:nil];
        }
    }];
    
    /*
     Given everything else is signed, we can now sign the main executable
    */
    [self resignBundle:appDir
      bundleExecutable:bundleExecPath
   appEntitlementsFile:appEntitlementsFile
      codesignIdentity:codesignIdentity];
    LogInfo(@"Done resigning %@ with %@.", appDirName, [profile name]);
}

+ (void)prepareResign:(Application *)app {
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    //Remove .DS_STORE if any
    NSString *dsStorePath = [app.path joinPath:@".DS_STORE"];
    if ([mgr fileExistsAtPath:dsStorePath]) {
        NSError *e = nil;
        [mgr removeItemAtPath:dsStorePath error:&e];
        NSAssert(e == nil, @"Error deleting .DS_STORE: %@", e);
        LogInfo(@"Deleted .DS_STORE");
    }
}

@end
