
#import "DeviceTestParameters.h"
#import "ShellRunner.h"

@implementation DeviceTestParameters
- (id)init {
    if (self = [super init]) {
        self.deviceType = kDeviceTypeDevice;
    }
    return self;
}

- (instancetype)validate {
    if (![TestParameters isDeviceID:self.deviceID]) {
        [self failWith:@"Invalid device_id" ];
    }
    
    if (self.codesignIdentity == nil) {
        [self failWith:[NSString stringWithFormat:@"Must provide a codesigning identity with %@, e.g. \
             ('iPhone Developer: Aaron Aaronson (ABCDE12345)')",
             CODESIGN_IDENTITY_FLAG]];
    }
    
    NSFileManager *filemanager = [NSFileManager defaultManager];
    if (![filemanager fileExistsAtPath:self.pathToXcodePlatformDir]) {
        [self failWith:@"Could not find path to Xcode Platform dir. \
             Please ensure that running `xcode-select --print-path`\
             returns a valid value."];
    }
    
    return [super validate];
}

+ (NSString *)getXcodeDeveloperDir {
    NSArray *pathLines = [ShellRunner shell:@"/usr/bin/xcode-select"
                                       args:@[@"--print-path"]];
    if (pathLines == nil || pathLines.count == 0) exit(1);
    return pathLines[0];
}

+ (instancetype)fromJSON:(NSDictionary *)json {
    DeviceTestParameters *params = [DeviceTestParameters new];
    params.deviceID = json[DEVICE_ID_FLAG];
    params.testRunnerPath = json[TEST_RUNNER_PATH_FLAG];
    params.testBundlePath = json[XCTEST_BUNDLE_PATH_FLAG];
    params.codesignIdentity = json[CODESIGN_IDENTITY_FLAG];
    
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSString *pwd = [filemanager currentDirectoryPath];
    params.workingDirectory = pwd;
    
    NSString *fileName = [NSString stringWithFormat:@"%@_%@",
                          [[NSProcessInfo processInfo] globallyUniqueString], @"__appData.xcappdata"];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    params.applicationDataPath = filePath;
    
    
    params.pathToXcodePlatformDir = [self getXcodeDeveloperDir];
    params.deviceID = json[DEVICE_ID_FLAG];
    
    return params;
}
@end
