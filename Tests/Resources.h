#import <Foundation/Foundation.h>

@class ShellResult;
@class Entitlements;
@class CodesignIdentity;

#pragma mark - Version Inlines

NS_INLINE BOOL version_eql(NSString* a, NSString *b) {
    return [a compare:b options:NSNumericSearch] == NSOrderedSame;
}

NS_INLINE BOOL version_gt(NSString* a, NSString *b) {
    return [a compare:b options:NSNumericSearch] == NSOrderedDescending;
}

NS_INLINE BOOL version_gte(NSString* a, NSString *b) {
    return [a compare:b options:NSNumericSearch] != NSOrderedAscending;
}

NS_INLINE BOOL version_lt(NSString* a, NSString* b) {
    return [a compare:b options:NSNumericSearch] == NSOrderedAscending;
}

NS_INLINE BOOL version_lte(NSString* a, NSString* b) {
    return [a compare:b options:NSNumericSearch] != NSOrderedDescending;
}

#pragma mark - Constants

static NSString *const kProgramName = @"iOSDeviceManagement";

static NSString *const kCodeSignIdentityKARL =
@"iPhone Developer: Karl Krukow (YTTN6Y2QS9)";
static NSString *const kCodeSignIdentityMOODY =
@"iPhone Developer: Joshua Moody (8QEQJFT59F)";

static NSString *const kStockholmCoord = @"59.333422,18.065130";

static NSString *const ARM = @"ARM";
static NSString *const SIM = @"SIM";

@class TestSimulator;

#pragma mark - Simctl

@interface Simctl : NSObject

+ (Simctl *)shared;
- (NSArray<TestSimulator *> *)simulators;

@end

#pragma mark - TestSimulator (Class)


typedef NS_ENUM(NSUInteger, TestSimulatorState) {
    TestSimulatorStateCreating = 0,
    TestSimulatorStateShutdown = 1,
    TestSimulatorStateBooting = 2,
    TestSimulatorStateBooted = 3,
    TestSimulatorStateShuttingDown = 4,
    TestSimulatorStateUnknown = 99,
};

@interface TestSimulator : NSObject

- (id)initWithDictionary:(NSDictionary *)dictionary
                      OS:(NSString *)OS;
- (NSString *)UDID;
- (NSString *)name;
- (NSString *)OS;
- (BOOL)isIPad;
- (BOOL)isIPadPro;
- (BOOL)isIPadRetina;
- (BOOL)isIPadAir;
- (BOOL)isIPhone;
- (BOOL)isIPhone6;
- (BOOL)isIPhone6Plus;
- (BOOL)isIPhone4S;
- (BOOL)isIPhone5;
- (BOOL)isSModel;
- (TestSimulatorState)state;
- (NSString *)stateString;

@end

#pragma mark - TestDevice (Class)

@interface TestDevice : NSObject

- (id)initWithDictionary:(NSDictionary *)info;
- (NSString *)UDID;
- (NSString *)name;
- (NSString *)OS;
- (BOOL)isCompatibleWithCurrentXcode;

@end

#pragma mark - Instruments

@interface Instruments : NSObject

+ (Instruments *)shared;
- (NSArray<TestDevice *> *)connectedDevices;
- (NSArray<TestDevice *> *)compatibleDevices;
- (TestDevice *)deviceForTesting;

@end

#pragma mark - Resources

@interface Resources : NSObject

+ (Resources *) shared;
- (void)setDeveloperDirectory;

- (NSString *)XcodeVersion;
- (BOOL)XcodeGte80;

- (Simctl *)simctl;
- (NSArray<TestSimulator *> *)simulators;
- (TestSimulator *)defaultSimulator;
- (NSString *)defaultSimulatorUDID;

- (NSString *)uniqueFileToUpload;

- (Instruments *)instruments;
- (BOOL)isCompatibleDeviceConnected;
- (TestDevice *)defaultDevice;
- (NSString *)defaultDeviceUDID;

- (NSString *)TestAppPath:(NSString *)platform;
/*
    Relative path to a test app with at least one ".." in the path
*/
- (NSString *)TestAppRelativePath:(NSString *)platform;
- (NSString *)TestAppIdentifier;
- (NSString *)TaskyPath:(NSString *)platform;
- (NSString *)TaskyIpaPath;
- (NSString *)TaskyIdentifier;
- (NSString *)TestStructureDirectory;
- (NSString *)DeviceAgentPath:(NSString *)platform;
- (NSString *)DeviceAgentXCTestPath:(NSString *)platform;
- (NSString *)DeviceAgentIdentifier;

- (ShellResult *)successResultSingleLine;
- (ShellResult *)successResultMultiline;
- (ShellResult *)successResultWithFakeSigningIdentities;
- (ShellResult *)timedOutResult;
- (ShellResult *)failedResult;

- (NSString *)stringPlist;
- (NSString *)CalabashWildcardPath;
- (NSString *)pathToVeryLongProfile;
- (NSString *)provisioningProfilesDirectory;
- (NSString *)pathToCalabashWildcardPathCertificate;
- (NSData *)certificateFromCalabashWildcardPath;
- (Entitlements *)entitlements;
- (CodesignIdentity *)KarlKrukowIdentity;

- (NSString *)resourcesDirectory;
- (NSString *)plistPath:(NSString *)bundlePath;
- (NSDictionary *)infoPlist:(NSString *)bundlePath;
- (NSString *)bundleIdentifier:(NSString *)bundlePath;
- (BOOL)updatePlistForBundle:(NSString *)bundlePath
                         key:(NSString *)key
                       value:(NSString *)value;

- (NSString *)uniqueTmpDirectory;
- (NSString *)tmpDirectoryWithName:(NSString *)name;
- (void)copyDirectoryWithSource:(NSString *)source
                         target:(NSString *)target;

@end
