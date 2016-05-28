
#import <Foundation/Foundation.h>

typedef NS_ENUM(short, DeviceType) {
    kDeviceTypeDevice,
    kDeviceTypeSimulator
};

@class DeviceTestParameters, SimulatorTestParameters;

static NSString *const DEVICE_ID_FLAG = @"-d";
static NSString *const XCTEST_BUNDLE_PATH_FLAG = @"-t";
static NSString *const TEST_RUNNER_PATH_FLAG = @"-r";
static NSString *const CODESIGN_IDENTITY_FLAG = @"-c";

@interface TestParameters : NSObject
@property (nonatomic, strong) NSString *testBundlePath;
@property (nonatomic, strong) NSString *testRunnerPath;
@property (nonatomic, strong) NSString *deviceID;
@property (nonatomic) DeviceType deviceType;

+ (instancetype)fromJSON:(NSDictionary *)json;
- (DeviceTestParameters *)asDeviceTestParameters;
- (SimulatorTestParameters *)asSimulatorTestParameters;
- (instancetype)validate;

+ (BOOL)isSimulatorID:(NSString *)did;
+ (BOOL)isDeviceID:(NSString *)did;

- (void)failWith:(NSString *)message;
- (void)failWith:(NSString *)message exitCode:(int)exitCode;
@end
