#import "Resources.h"
#import "ShellRunner.h"
#import "TestParameters.h"
#import <sys/utsname.h>

@interface Simctl ()

@property(copy, readonly) NSArray<TestSimulator *> *simulators;

+ (BOOL)ensureValidCoreSimulatorService;

@end

@implementation Simctl

@synthesize simulators = _simulators;

+ (BOOL)ensureValidCoreSimulatorService {
    BOOL success = NO;
    NSDictionary *hash;
    NSUInteger maxTries = 10;
    for(NSUInteger try = 0; try < maxTries; try++) {
        hash = [ShellRunner xcrun:@[@"simctl", @"help"] timeout:10];

        if (!hash[@"success"]) {
            NSLog(@"Invalid CoreSimulator service for active Xcode: try %@ of %@",
                  @(try + 1), @(maxTries));
        } else {
            NSLog(@"Valid CoreSimulator service for active Xcode after %@ tries",
                  @(try + 1));
            success = YES;
            break;
        }
    }
    return success;
}

+ (Simctl *)shared {
    static Simctl *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[Simctl alloc] init];
        [Simctl ensureValidCoreSimulatorService];
    });
    return shared;
}

- (NSArray<TestSimulator *> *)simulators {
    if (_simulators) { return _simulators; }

    NSArray<NSString *> *lines = [ShellRunner xcrun:@[@"simctl", @"list",
                                                      @"devices", @"--json"]];
    NSLog(@"lines = %@", lines);
    NSString *json = [lines componentsJoinedByString:@"\n"];

    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *raw =
    [NSJSONSerialization JSONObjectWithData:data
                                    options:NSJSONReadingMutableContainers
                                      error:nil];

    NSDictionary *devices = raw[@"devices"];
    NSMutableArray<TestSimulator *> *sims = [NSMutableArray array];

    [devices enumerateKeysAndObjectsUsingBlock:^(NSString  *OSKey, NSArray *list,
                                                 BOOL *stop) {

        if ([self isIOS:OSKey] && [self isOSGte90:OSKey]) {
            for (NSDictionary *simulator in list) {
                if ([self isSimulatorAvailable:simulator]) {
                    NSString *OS = [self versionFromOSKey:OSKey];
                    [sims addObject:[[TestSimulator alloc]
                                     initWithDictionary:simulator
                                     OS:OS]];
                }
            }
        }
    }];

    _simulators = [NSArray arrayWithArray:sims];
    return _simulators;
}

- (BOOL)isIOS:(NSString *)OSKey {
    return [OSKey hasPrefix:@"iOS"];
}

- (NSString *)versionFromOSKey:(NSString *)OSKey {
    return [OSKey componentsSeparatedByString:@" "][1];
}

- (BOOL)isOSGte90:(NSString *)OSKey {
    return version_gte([self versionFromOSKey:OSKey], @"9.0");
}

- (BOOL)isSimulatorAvailable:(NSDictionary *)simulator {
    NSString *availability = simulator[@"availability"];
    return ![availability containsString:@"unavailable"];
}

@end

@interface TestSimulator ()

@property(copy) NSDictionary *info;
@property(copy) NSString *OS;

@end

@implementation TestSimulator

- (id)initWithDictionary:(NSDictionary *)info
                      OS:(NSString *)OS {
    self = [super init];
    if (self) {
        _info = info;
        _OS = OS;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"#<TestSim '%@' %@ : %@",
            [self name], self.OS, [self UDID]];
}

- (NSString *)UDID {
    return self.info[@"udid"];
}

- (NSString *)name {
    return self.info[@"name"];
}

- (BOOL)isIPad {
    return [[self name] containsString:@"iPad"];
}

- (BOOL)isIPadPro {
    return [[self name] containsString:@"iPad Pro"];
}

- (BOOL)isIPadRetina {
    return [[self name] containsString:@"iPad Retina"];
}

- (BOOL)isIPadAir {
    return [[self name] containsString:@"iPad Air"];
}

- (BOOL)isIPhone {
    return [[self name] containsString:@"iPhone"];
}

- (BOOL)isIPhone6 {
    return
    [[self name] containsString:@"iPhone 6"] &&
    ![[self name] containsString:@"Plus"];
}

- (BOOL)isIPhone6Plus {
    return [[self name] containsString:@"Plus"];
}

- (BOOL)isIPhone4S {
    return [[self name] containsString:@"4S"];
}
- (BOOL)isIPhone5 {
    return [[self name] containsString:@"iPhone 5"];
}

- (BOOL)isSModel {
    if (![self isIPhone]) { return NO; }
    if ([self isIPhone4S]) { return YES; }

    NSArray *tokens = [[self name] componentsSeparatedByString:@" "];
    return [tokens[1] containsString:@"s"];
}

@end

#pragma mark - TestDevice

@interface TestDevice ()

@property(copy, readonly) NSDictionary *info;

@end

@implementation TestDevice

@synthesize info = _info;

- (id)initWithDictionary:(NSDictionary *)info {
    self = [super init];
    if (self) {
        _info = info;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"#<TestDevice '%@' %@ : %@",
            [self name], self.OS, [self UDID]];
}

- (NSString *)UDID {
    return self.info[@"UDID"];
}

- (NSString *)name {
    return self.info[@"name"];
}

- (NSString *)OS {
    return self.info[@"OS"];
}

- (BOOL)isCompatibleWithCurrentXcode {
    if ([[Resources shared] XcodeGte80]) {
        return version_gte(self.OS, @"10.0");
    } else {
        return version_lt(self.OS, @"10.0");
    }
}

@end

#pragma mark - Instruments

@interface Instruments ()

@property(strong, readonly) NSRegularExpression *UDIDRegex;
@property(strong, readonly) NSRegularExpression *VersionRegex;
@property(copy, readonly) NSArray<TestDevice *> *connectedDevices;
@property(copy, readonly) NSArray<TestDevice *> *compatibleDevices;

@end

@implementation Instruments

@synthesize UDIDRegex = _UDIDRegex;
@synthesize VersionRegex = _VersionRegex;
@synthesize connectedDevices = _connectedDevices;
@synthesize compatibleDevices = _compatibleDevices;

+ (Instruments *)shared {
    static Instruments *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[Instruments alloc] init];
        // Make sure there is a valid CoreSimulatorService
        [Simctl shared];
    });
    return shared;
}

- (NSArray<TestDevice *> *)connectedDevices {
    if (_connectedDevices) { return _connectedDevices; }

    NSArray<NSString *> *lines =
    [ShellRunner xcrun:@[@"instruments", @"-s", @"devices"]];

    NSMutableArray<TestDevice *> *result = [@[] mutableCopy];

    [lines enumerateObjectsUsingBlock:^(NSString *line,
                                        NSUInteger idx,
                                        BOOL *stop) {
        NSString *udid = [self extractUDID:line];
        if ([TestParameters isDeviceID:udid]) {
            NSMutableDictionary *info = [@{} mutableCopy];
            info[@"UDID"] = udid;
            info[@"OS"] = [self extractVersion:line];
            info[@"name"] = [[line
                              componentsSeparatedByString:@"("][0]
                             stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceCharacterSet]];

            TestDevice *device = [[TestDevice alloc]
                                  initWithDictionary:[NSDictionary
                                                      dictionaryWithDictionary:info]];
            [result addObject:device];
        }
    }];

    _connectedDevices = [NSArray arrayWithArray:result];

    return _connectedDevices;
}

- (NSArray<TestDevice *> *)compatibleDevices {
    if (_compatibleDevices) { return _compatibleDevices; }

    NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(TestDevice *device,
                                                                id bindings) {
        return [device isCompatibleWithCurrentXcode];
    }];

    _compatibleDevices = [self.connectedDevices filteredArrayUsingPredicate:filter];

    return _compatibleDevices;
}

- (TestDevice *)deviceForTesting {
    return self.compatibleDevices[0];
}

- (NSRegularExpression *)UDIDRegex {
    if (_UDIDRegex) { return _UDIDRegex; }
    _UDIDRegex = [NSRegularExpression regularExpressionWithPattern:@"([a-f0-9]{40})"
                                                           options:0
                                                             error:NULL];
    return _UDIDRegex;
}

- (NSRegularExpression *)VersionRegex {
    if (_VersionRegex) { return _VersionRegex; }
    _VersionRegex = [NSRegularExpression
                     regularExpressionWithPattern:@"(\\d+.\\d+(.\\d+)?)"
                     options:0
                     error:NULL];
    return _VersionRegex;
}

- (NSString *)extractUDID:(NSString *)string {
    return [self stringByExtractingRegex:self.UDIDRegex
                              fromString:string];
}

- (NSString *)extractVersion:(NSString *)string {
    return [self stringByExtractingRegex:self.VersionRegex
                              fromString:string];
}

- (NSString *)stringByExtractingRegex:(NSRegularExpression *)regex
                           fromString:(NSString *)string {
    NSRange range = NSMakeRange(0, [string length]);
    NSRange match = [regex rangeOfFirstMatchInString:string
                                             options:0
                                               range:range];
    if (match.location != NSNotFound) {
        return [string substringWithRange:match];
    } else {
        return nil;
    }
}

@end

#pragma mark - Resources

@interface Resources ()

@property(strong, readonly) TestSimulator *defaultSimulator;
@property(copy, readonly) NSString *defaultSimulatorUDID;
@property(strong, readonly) TestDevice *defaultDevice;
@property(copy, readonly) NSString *defaultDeviceUDID;


@property(copy, readonly) NSString *resourcesDirectory;
@property(copy, readonly) NSString *TMP;
@property(copy, readonly) NSString *OSVersion;
@property(copy, readonly) NSString *XcodeVersion;
@property(copy, readonly) NSString *XcodeSelectPath;
@property(copy, readonly) NSString *XcodeFromProcessPATH;
@property(copy, readonly) NSString *XcodePath;

- (BOOL)createDirectoryAtPath:(NSString *)path error:(NSError **)error;
- (void)createDirectoryAtPath:(NSString *)path failureMessage:(NSString *)string;

@end

static NSString *const kTmpDirectory = @".iOSDeviceManager/Tests/";

@implementation Resources

@synthesize defaultSimulator = _defaultSimulator;
@synthesize defaultSimulatorUDID = _defaultSimulatorUDID;
@synthesize defaultDevice = _defaultDevice;
@synthesize defaultDeviceUDID = _defaultDeviceUDID;
@synthesize resourcesDirectory = _resourcesDirectory;
@synthesize TMP = _TMP;
@synthesize OSVersion = _OSVersion;
@synthesize XcodeVersion = _XcodeVersion;
@synthesize XcodeSelectPath = _XcodeSelectPath;
@synthesize XcodeFromProcessPATH = _XcodeFromProcessPath;
@synthesize XcodePath = _XcodePath;

+ (Resources *) shared {
    static Resources *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[Resources alloc] init];
    });
    return shared;
}

#pragma mark - macOS and Xcode

- (NSString *)OSVersion {
    if (_OSVersion) { return _OSVersion; }

    struct utsname systemInfo;
    uname(&systemInfo);
    _OSVersion = @(systemInfo.release);

    return _OSVersion;
}

- (BOOL)OSisSierraOrHigher {
    return version_gte(self.OSVersion, @"16.0.0");
}

- (NSString *)XcodeSelectPath {
    if (_XcodeSelectPath) { return _XcodeSelectPath; }

    _XcodeSelectPath = [ShellRunner shell:@"/usr/bin/xcode-select"
                                     args:@[@"--print-path"]][0];

    return _XcodeSelectPath;
}

- (NSString *)XcodeFromProcessPATH {
    if (_XcodeFromProcessPath) { return _XcodeFromProcessPath; }

    NSDictionary *environment = [[NSProcessInfo processInfo] environment];

    if (environment[@"DTX_CONNECTION_SERVICES_PATH"]) {
        _XcodeFromProcessPath = [[[environment[@"DTX_CONNECTION_SERVICES_PATH"]
                                   stringByDeletingLastPathComponent]
                                  stringByDeletingLastPathComponent]
                                 stringByAppendingPathComponent:@"Developer"];
    } else if (environment[@"DYLD_FALLBACK_FRAMEWORK_PATH"]) {
        _XcodeFromProcessPath = [[environment[@"DYLD_FALLBACK_FRAMEWORK_PATH"]
                                  stringByDeletingLastPathComponent]
                                 stringByDeletingLastPathComponent];
    }

    if (!_XcodeFromProcessPath ||
        ![_XcodeFromProcessPath containsString:@".app/Contents/Developer"]) {
        NSLog(@"======= ENVIRONMENT =======");
        NSLog(@"%@", environment);
        NSString *reason;
        reason = [NSString
                  stringWithFormat:@"Cannot detect Xcode from process environment:\n"
                  "_XcodeFromProcessPath = %@", _XcodeFromProcessPath];
        @throw [NSException exceptionWithName:@"Xcode?"
                                       reason:reason
                                     userInfo:nil];
    }

    return _XcodeFromProcessPath;
}

- (NSString *)XcodePath {
    if (_XcodePath) { return _XcodePath; }
    NSString *processPath = self.XcodeFromProcessPATH;
    NSString *xcodeSelectPath = self.XcodeSelectPath;

    if ([processPath isEqualToString:xcodeSelectPath]) {
        _XcodePath = xcodeSelectPath;
    } else {
        _XcodePath = processPath;
    }
    return _XcodePath;
}

- (NSString *)XcodeVersion {
    if (_XcodeVersion) { return _XcodeVersion; }
    NSString *bundlePath = [self.XcodePath stringByDeletingLastPathComponent];
    _XcodeVersion = [self infoPlist:bundlePath][@"CFBundleShortVersionString"];
    return _XcodeVersion;
}


- (BOOL)XcodeGte80 {
    return version_gte(self.XcodeVersion, @"8.0");
}

- (void)setDeveloperDirectory {
    if (self.OSisSierraOrHigher) {
        NSLog(@"Only Xcode 8 is allowed on Sierra; "
              "don't touch the active Xcode version");
    } else {
        NSLog(@"Setting DEVELOPER_DIR to avoid CoreSimulatorService mismatch");
        setenv("DEVELOPER_DIR",
               [self.XcodePath cStringUsingEncoding:NSUTF8StringEncoding],
               YES);
    }
}

- (NSString *)resourcesDirectory {
    if (_resourcesDirectory) { return _resourcesDirectory; }

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    _resourcesDirectory = [[bundle resourcePath]
                           stringByAppendingPathComponent:@"Resources"];
    return _resourcesDirectory;
}

- (NSString *)TestAppPath:(NSString *)platform {
    if ([ARM isEqualToString:platform]) {
        return [self.resourcesDirectory
                stringByAppendingPathComponent:@"arm/TestApp.app"];
    } else if ([SIM isEqualToString:platform]) {
        return [self.resourcesDirectory
                stringByAppendingPathComponent:@"sim/TestApp.app"];
    } else {
        return nil;
    }
}

- (NSString *)TestAppIdentifier {
    return [self bundleIdentifier:[self TestAppPath:ARM]];
}

- (NSString *)TaskyPath:(NSString *)platform {
    if ([ARM isEqualToString:platform]) {
        return [self.resourcesDirectory
                stringByAppendingPathComponent:@"arm/TaskyiOS.app"];
    } else if ([SIM isEqualToString:platform]) {
        return [self.resourcesDirectory
                stringByAppendingPathComponent:@"sim/TaskyiOS.app"];
    } else {
        return nil;
    }
}

- (NSString *)TaskyIpaPath {
    return [self.resourcesDirectory
            stringByAppendingPathComponent:@"arm/TaskyPro.ipa"];
}

- (NSString *)TaskyIdentifier {
    return [self bundleIdentifier:[self TaskyPath:ARM]];
}

- (NSString *)DeviceAgentPath:(NSString *)platform {
    if ([ARM isEqualToString:platform]) {
        return [self.resourcesDirectory
                stringByAppendingPathComponent:@"arm/DeviceAgent-Runner.app"];
    } else if ([SIM isEqualToString:platform]) {
        return [self.resourcesDirectory
                stringByAppendingPathComponent:@"sim/DeviceAgent-Runner.app"];
    } else {
        return nil;
    }
}

- (NSString *)DeviceAgentXCTestPath:(NSString *)platform {
    if ([ARM isEqualToString:platform]) {
        return [[self DeviceAgentPath:ARM]
                stringByAppendingPathComponent:@"PlugIns/DeviceAgent.xctest"];
    } else if ([SIM isEqualToString:platform]) {
        return [[self DeviceAgentPath:SIM]
                stringByAppendingPathComponent:@"PlugIns/DeviceAgent.xctest"];
    } else {
        return nil;
    }
}

- (NSString *)DeviceAgentIdentifier {
    return [self bundleIdentifier:[self DeviceAgentPath:ARM]];
}

- (NSString *)plistPath:(NSString *)bundlePath {
    return [bundlePath stringByAppendingPathComponent:@"Info.plist"];
}

- (NSDictionary *)infoPlist:(NSString *)bundlePath {
    NSString *path = [self plistPath:bundlePath];
    return [NSDictionary dictionaryWithContentsOfFile:path];
}

- (NSString *)bundleIdentifier:(NSString *)bundlePath {
    NSDictionary *dictionary = [self infoPlist:bundlePath];
    return dictionary[@"CFBundleIdentifier"];
}

- (BOOL)updatePlistForBundle:(NSString *)bundlePath
                         key:(NSString *)key
                       value:(NSString *)value {

    NSMutableDictionary *plist = [[self infoPlist:bundlePath] mutableCopy];
    plist[key] = value;
    return [plist writeToFile:[self plistPath:bundlePath] atomically:YES];
}

#pragma mark - TMP Directories

- (NSString *)TMP {
    if (_TMP) { return _TMP; }
    _TMP = [NSHomeDirectory() stringByAppendingPathComponent:kTmpDirectory];

    [self deleteDirectoryAtPath:_TMP
                  failureMessge:@"Could not delete existing TMP directory"];
    [self createDirectoryAtPath:_TMP
                 failureMessage:@"Could not create TMP directory"];
    return _TMP;
}

- (NSString *)uniqueTmpDirectory {
    NSString *UUID = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *path = [[self TMP] stringByAppendingPathComponent:UUID];
    [self createDirectoryAtPath:path
                 failureMessage:@"Could not create unique tmp directory"];
    return path;
}

- (NSString *)tmpDirectoryWithName:(NSString *)name {
    NSString *path = [[self TMP] stringByAppendingPathComponent:name];

    [self deleteDirectoryAtPath:path
                  failureMessge:@"Error deleting existing tmp directory"];
    [self createDirectoryAtPath:path
                 failureMessage:@"Could not create tmp subdirectory"];
    return path;
}

- (void)copyDirectoryWithSource:(NSString *)source
                         target:(NSString *)target {
    NSFileManager *manager = [NSFileManager defaultManager];

    [self deleteDirectoryAtPath:target
                  failureMessge:@"Could not delete existing target"];

    NSError *error;
    if (![manager copyItemAtPath:source
                          toPath:target error:&error]) {
        @throw [NSException exceptionWithName:@"Error copying directory"
                                       reason:[error localizedDescription]
                                     userInfo:nil];
    }
}

- (BOOL)createDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSFileManager *manager = [NSFileManager defaultManager];
    return [manager createDirectoryAtPath:path
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:error];
}

- (void)createDirectoryAtPath:(NSString *)path failureMessage:(NSString *)message {
    NSError *error;

    if (![self createDirectoryAtPath:path error:&error]) {
        NSString *reason;
        reason = [NSString stringWithFormat:@"%@: %@", message,
                  [error localizedDescription]];
        @throw [NSException exceptionWithName:@"File IO Exception"
                                       reason:reason
                                     userInfo:nil];
    }
}

- (BOOL)deleteDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:path]) {
        return [manager removeItemAtPath:path error:error];
    } else {
        return YES;
    }
}

- (void)deleteDirectoryAtPath:(NSString *)path failureMessge:(NSString *)message {
    NSError *error;
    if (![self deleteDirectoryAtPath:path error:&error]) {
        NSString *reason;
        reason = [NSString stringWithFormat:@"%@: %@", message,
                  [error localizedDescription]];
        @throw [NSException exceptionWithName:@"File IO Exception"
                                       reason:reason
                                     userInfo:nil];
    }
}

#pragma mark - Simulators

- (Simctl *)simctl {
    return [Simctl shared];
}

- (NSArray<TestSimulator *> *)simulators {
    return [[self simctl] simulators];
}

- (TestSimulator *)defaultSimulator {
    if (_defaultSimulator) { return _defaultSimulator; }

    NSArray *simulators = self.simulators;
    TestSimulator *candidate = nil;
    for (TestSimulator *simulator in simulators) {
        if ([simulator isIPhone6] && [simulator isSModel]) {
            if (candidate) {
                NSString *simulatorOS = [simulator OS];
                NSString *candidateOS = [candidate OS];
                if (version_gte(simulatorOS, candidateOS)) {
                    candidate = simulator;
                }
            } else {
                candidate = simulator;
            }
        }
    }

    _defaultSimulator = candidate;
    return _defaultSimulator;
}

- (NSString *)defaultSimulatorUDID {
    if (_defaultSimulatorUDID) { return _defaultSimulatorUDID; }

    _defaultSimulatorUDID = [self.defaultSimulator UDID];
    return _defaultSimulatorUDID;
}

#pragma mark - Physical Device

- (Instruments *)instruments {
    return [Instruments shared];
}

- (TestDevice *)defaultDevice {
    if (_defaultDevice) { return _defaultDevice; }

    if (![self isCompatibleDeviceConnected]) { return nil; }

    _defaultDevice = [[self instruments] deviceForTesting];
    return _defaultDevice;
}

- (NSString *)defaultDeviceUDID {
    if (_defaultDeviceUDID) { return _defaultDeviceUDID; }

    if (![self isCompatibleDeviceConnected]) { return nil; }
    
    _defaultDeviceUDID = [[self defaultDevice] UDID];
    
    return _defaultDeviceUDID;
}

- (BOOL)isCompatibleDeviceConnected {
    return [[[self instruments] compatibleDevices] count] != 0;
}

@end
