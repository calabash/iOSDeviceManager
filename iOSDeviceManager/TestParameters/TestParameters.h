
#import <Foundation/Foundation.h>

@class DeviceTestParameters, SimulatorTestParameters;

@interface TestParameters : NSObject
+ (BOOL)isSimulatorID:(NSString *)did;
+ (BOOL)isDeviceID:(NSString *)did;
@end
