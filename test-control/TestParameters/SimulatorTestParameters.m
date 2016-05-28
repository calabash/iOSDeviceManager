
#import "SimulatorTestParameters.h"

@implementation SimulatorTestParameters
- (id)init {
    if (self = [super init]) {
        self.deviceType = kDeviceTypeSimulator;
    }
    return self;
}

- (instancetype)validate {
    if (![TestParameters isSimulatorID:self.deviceID]) {
        [self failWith:[NSString stringWithFormat:@"%@ is not a simulator ID", self.deviceID]];
    }
    return [super validate];
}

+ (instancetype)fromJSON:(NSDictionary *)json {
    SimulatorTestParameters *params = [SimulatorTestParameters new];
    params.deviceID = json[DEVICE_ID_FLAG];
    params.testRunnerPath = json[TEST_RUNNER_PATH_FLAG];
    params.testBundlePath = json[XCTEST_BUNDLE_PATH_FLAG];
    return params;
}

@end
