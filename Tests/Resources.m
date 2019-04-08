#import "Resources.h"
#import "ShellRunner.h"
#import "ShellResult.h"
#import "Entitlements.h"
#import "CodesignIdentity.h"
#import <sys/utsname.h>
#import "Device.h"
#import "DeviceUtils.h"

@interface Simctl ()

@property(copy, readonly) NSArray<TestSimulator *> *simulators;

+ (BOOL)ensureValidCoreSimulatorService;

@end

@implementation Simctl

@synthesize simulators = _simulators;

+ (BOOL)ensureValidCoreSimulatorService {
    BOOL success = NO;
    NSUInteger maxTries = 10;
    for(NSUInteger try = 0; try < maxTries; try++) {
        ShellResult *result = [ShellRunner xcrun:@[@"simctl", @"help"] timeout:10];

        if (!result.success) {
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
                                                      @"devices", @"--json"]
                                            timeout:10.0].stdoutLines;
    NSString *json = [lines componentsJoinedByString:@" "];

    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *raw =
    [NSJSONSerialization JSONObjectWithData:data
                                    options:NSJSONReadingMutableContainers
                                      error:&error];

    if (!raw) {
       NSLog(@"Could not list create a list of simulators with simctl");
       NSLog(@"Error: %@", error);
       return nil;
    }

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
    return [OSKey containsString:@"iOS"];
}

- (NSString *)versionFromOSKey:(NSString *)OSKey {
    if ([OSKey containsString:@""]) {
        return [OSKey componentsSeparatedByString:@" "][1];
    }
    NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"(?:\\d+-?)+$" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSTextCheckingResult *newSearchString = [regEx firstMatchInString:OSKey options:0 range:NSMakeRange(0, [OSKey length])];
    NSString *OSKeyVersionXcodeGte101 = [OSKey substringWithRange:newSearchString.range];
    return [OSKeyVersionXcodeGte101 stringByReplacingOccurrencesOfString:@"-" withString:@"."];
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
@property(copy, readonly) NSString *directory;
@property(copy, readonly) NSString *plist;

@end

@implementation TestSimulator

@synthesize directory = _directory;
@synthesize plist = _plist;

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

- (NSString *)directory {
    if (_directory) { return _directory; }
    _directory = [[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
                                        stringByAppendingPathComponent:@"Developer"]
                                        stringByAppendingPathComponent:@"CoreSimulator"]
                                        stringByAppendingPathComponent:@"Devices"]
                                        stringByAppendingPathComponent:self.UDID];
    return _directory;
}

- (NSString *)plist {
    if (_plist) { return _plist; }

    _plist = [[self directory] stringByAppendingPathComponent:@"device.plist"];
    return _plist;
}

- (TestSimulatorState)state {
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[self plist]];
    NSNumber *number = (NSNumber *)dictionary[@"state"];
    return (TestSimulatorState)[number unsignedIntegerValue];
}

- (NSString *)stateString {
    TestSimulatorState state = [self state];

    switch (state) {
        case TestSimulatorStateCreating : { return @"Creating"; }
        case TestSimulatorStateShutdown : { return @"Shutdown"; }
        case TestSimulatorStateBooting : { return @"Booting"; }
        case TestSimulatorStateShuttingDown : { return @"Shutting Down"; }
        default: { return @"UNKNOWN"; }
    }
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

    NSArray<NSString *> *lines;
    lines = [ShellRunner xcrun:@[@"instruments", @"-s", @"devices"]
                       timeout:10].stdoutLines;

    NSMutableArray<TestDevice *> *result = [@[] mutableCopy];

    [lines enumerateObjectsUsingBlock:^(NSString *line,
                                        NSUInteger idx,
                                        BOOL *stop) {
        NSString *udid = [self extractUDID:line];
        if ([DeviceUtils isDeviceID:udid]) {
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
    if (self.compatibleDevices.count > 0) {
        return self.compatibleDevices[0];
    } else {
        return nil;
    }
}

- (NSRegularExpression *)UDIDRegex {
    if (_UDIDRegex) { return _UDIDRegex; }
    _UDIDRegex = [NSRegularExpression regularExpressionWithPattern:@"([a-f0-9]{40}|([A-F0-9]{8}-[A-F0-9]{16}))"
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

@property(copy) NSMutableData *responseData;
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

@property(strong, readonly) ShellResult *successResultSingleLine;
@property(strong, readonly) ShellResult *successResultMultiline;
@property(strong, readonly) ShellResult *successWithFakeSigningIdentities;
@property(strong, readonly) ShellResult *timedOutResult;
@property(strong, readonly) ShellResult *failedResult;

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
@synthesize successResultSingleLine = _successResultSingleLine;
@synthesize successResultMultiline = _successResultMultiline;
@synthesize successWithFakeSigningIdentities = _successWithFakeSigningIdentities;
@synthesize timedOutResult = _timedOutResult;
@synthesize failedResult = _failedResult;

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

    _XcodeSelectPath = [ShellRunner command:@"/usr/bin/xcode-select"
                                       args:@[@"--print-path"]
                                    timeout:10].stdoutLines[0];

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
    } else if (environment[@"PATH"]) {
        NSArray *tokens = [environment[@"PATH"] componentsSeparatedByString:@":"];
        NSString *xcodeUsrBin = tokens[0];
        _XcodeFromProcessPath = [[xcodeUsrBin stringByDeletingLastPathComponent]
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
    NSLog(@"Setting DEVELOPER_DIR to avoid CoreSimulatorService mismatch");
    setenv("DEVELOPER_DIR",
           [self.XcodePath cStringUsingEncoding:NSUTF8StringEncoding],
           YES);
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

- (NSString *)TestAppRelativePath:(NSString *)platform {
    if ([ARM isEqualToString:platform]) {
        return [self.resourcesDirectory
                stringByAppendingPathComponent:@"arm/../arm/TestApp.app"];
    } else if ([SIM isEqualToString:platform]) {
        return [self.resourcesDirectory
                stringByAppendingPathComponent:@"sim/../sim/TestApp.app"];
    } else {
        return nil;
    }
}

/*
    Copy the testfile to a unique filename in the tmp dir and return that
 */
- (NSString *)uniqueFileToUpload {
    NSString *uploadFile = [[self resourcesDirectory] stringByAppendingPathComponent:@"testfile.txt"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *tmp = [NSTemporaryDirectory() stringByAppendingPathComponent:guid];
    [fm copyItemAtPath:uploadFile toPath:tmp error:nil];
    return tmp;
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

- (NSString *)TestStructureDirectory {
    return [self.resourcesDirectory
            stringByAppendingPathComponent:@"testDirectoryStructure"];
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

- (NSString *)CalabashDylibPath {
    return [self.resourcesDirectory stringByAppendingPathComponent:@"calabash.dylib"];
}

- (NSString *)PermissionsAppBundleID {
    return @"sh.calaba.Permissions";
}

- (NSString *)PermissionsIpaPath {
    return [self.resourcesDirectory stringByAppendingPathComponent:@"arm/Permissions.ipa"];
}

- (NSString *)TestRecorderDylibPath {
    return [self.resourcesDirectory stringByAppendingPathComponent:@"recorderPluginCalabash.dylib"];
}

- (ShellResult *)successResultSingleLine {
    if (_successResultSingleLine) { return _successResultSingleLine; }

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/echo"];
    [task setArguments:@[@"-n", @"Hello"]];

    NSPipe *outPipe = [NSPipe pipe];
    [task setStandardOutput:outPipe];

    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardError:errPipe];

    [task launch];
    [task waitUntilExit];

    _successResultSingleLine = [ShellResult withTask:task elapsed:1.0 didTimeOut:NO];
    return _successResultSingleLine;
}

- (ShellResult *)successResultMultiline {
    if (_successResultMultiline) { return _successResultMultiline; }

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/echo"];
    [task setArguments:@[@"Hello\nNewline"]];

    NSPipe *outPipe = [NSPipe pipe];
    [task setStandardOutput:outPipe];

    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardError:errPipe];

    [task launch];
    [task waitUntilExit];

    _successResultMultiline = [ShellResult withTask:task elapsed:1.0 didTimeOut:NO];
    return _successResultMultiline;
}

- (ShellResult *)successResultWithFakeSigningIdentities {
    if (_successWithFakeSigningIdentities) { return _successWithFakeSigningIdentities; }

    NSString *path = [self.resourcesDirectory stringByAppendingPathComponent:@"identities.out"];

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/cat"];
    [task setArguments:@[path]];

    NSPipe *outPipe = [NSPipe pipe];
    [task setStandardOutput:outPipe];

    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardError:errPipe];

    [task launch];
    [task waitUntilExit];

    _successWithFakeSigningIdentities = [ShellResult withTask:task elapsed:1.0 didTimeOut:NO];
    return _successWithFakeSigningIdentities;
}

- (ShellResult *)timedOutResult {
    if (_timedOutResult) { return _timedOutResult; }

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sleep"];
    [task setArguments:@[@"1.0"]];

    NSPipe *outPipe = [NSPipe pipe];
    [task setStandardOutput:outPipe];

    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardError:errPipe];

    NSDate *endDate = [[NSDate date] dateByAddingTimeInterval:0.05];

    [task launch];

    while ([task isRunning]) {
        if ([endDate earlierDate:[NSDate date]] == endDate) {
            [task terminate];
        }
    }

    _timedOutResult = [ShellResult withTask:task elapsed:1.0 didTimeOut:YES];
    return _timedOutResult;
}

- (ShellResult *)failedResult {
    if (_failedResult) { return _failedResult; }
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/uname"];
    [task setArguments:@[@"-q"]];

    NSPipe *outPipe = [NSPipe pipe];
    [task setStandardOutput:outPipe];

    NSPipe *errPipe = [NSPipe pipe];
    [task setStandardError:errPipe];

    [task launch];
    [task waitUntilExit];

    _failedResult = [ShellResult withTask:task elapsed:1.0 didTimeOut:NO];
    return _failedResult;
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

#pragma mark - Code Signing

- (NSString *)stringPlist {
    return @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
    "<plist version=\"1.0\">\n"
    "<dict>\n"
    "<key>KEY</key>\n"
    "<string>VALUE</string>\n"
    "</dict>\n"
    "</plist>\n";
}

- (NSString *)CalabashWildcardPath {
    return [self.resourcesDirectory
            stringByAppendingPathComponent:@"profiles/CalabashWildcard.mobileprovision"];
}

- (NSString *)PermissionsProfilePath {
    return [self.resourcesDirectory
            stringByAppendingPathComponent:@"profiles/PermissionsDevelopment.mobileprovision"];
}

- (NSString *)pathToVeryLongProfile {
    return [self.provisioningProfilesDirectory stringByAppendingPathComponent:@"very-long-profile.mobileprovision"];
}

- (NSString *)pathToLJSProvisioningProfile {
    return [[self provisioningProfilesDirectory]
            stringByAppendingPathComponent:@"LJS_Development_Profile.mobileprovision"];
}

- (NSString *)provisioningProfilesDirectory {
    return [self.resourcesDirectory stringByAppendingPathComponent:@"profiles"];
}

- (NSString *)pathToCalabashWildcardPathCertificate {
    return [self.resourcesDirectory
            stringByAppendingPathComponent:@"cert-from-CalabashWildcardProfile.cert"];

}

- (NSData *)certificateFromCalabashWildcardPath {
    NSString *path = [self pathToCalabashWildcardPathCertificate];
    return [[NSData alloc] initWithContentsOfFile:path
                                          options:NSDataReadingUncached
                                            error:nil];
}

- (Entitlements *)entitlements {
    NSDictionary *dictionary = @{
                                 @"application-identifier" : @"FYD86LA7RE.sh.calaba.TestApp",
                                 @"com.apple.developer.team-identifier" : @"FYD86LA7RE",
                                 @"get-task-allow" : @(YES),
                                 @"keychain-access-groups" : @[@"FYD86LA7RE.sh.calaba.TestApp"]
                                 };
    return [Entitlements entitlementsWithDictionary:dictionary];
}

- (CodesignIdentity *)KarlKrukowIdentityIOS {
    NSString *identityName = @"iPhone Developer: Karl Krukow (YTTN6Y2QS9)";
    NSString *identityShasum = @"F1C2B010FDE010A3F6C29B1AFA4ADDCF704842A8";
    return [[CodesignIdentity alloc] initWithShasum:identityShasum
                                               name:identityName];
}

- (CodesignIdentity *)JoshuaMoodyIdentityIOS {
    NSString *identityName = @"iPhone Developer: Joshua Moody (8QEQJFT59F)";
    NSString *identityShasum = @"07692C2444C18782ED337F68F8E3FC7B81B1B5D8";
    return [[CodesignIdentity alloc] initWithShasum:identityShasum
                                               name:identityName];
}

#pragma mark - Simulators

- (Simctl *)simctl {
    return [Simctl shared];
}

- (NSArray<TestSimulator *> *)simulators {
    return [[self simctl] simulators];
}

#pragma mark - Physical Device

- (Instruments *)instruments {
    return [Instruments shared];
}

- (BOOL)isCompatibleDeviceConnected {
    return [[[self instruments] compatibleDevices] count] != 0;
}

- (NSString *)TestRecorderVersionFromHost:(NSString *)host {
    // Host name should not contain spaces
    NSString *encodedHost = [host stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    NSString *recorderUrl = [NSString stringWithFormat:@"http://%@:37265/recorderVersion", encodedHost];
    NSURL *url = [NSURL URLWithString:recorderUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];

    __block NSData *data = nil;
    __block NSError *outerError = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask;
    dataTask = [session dataTaskWithRequest:request
                        completionHandler:^(NSData *taskData,
                                            NSURLResponse *response,
                                            NSError *error) {
                          data = taskData;
                          outerError = error;
                          dispatch_semaphore_signal(semaphore);
                        }];
    [dataTask resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    if (!data) {
        return nil;
    } else {
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:&outerError];
        if (!dictionary) {
            return nil;
        } else {
            return (NSString *)dictionary[@"results"];
        }
    }
}

@end
