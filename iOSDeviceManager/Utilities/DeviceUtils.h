#import <Foundation/Foundation.h>
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>

@interface DeviceUtils : NSObject
+ (BOOL)isDeviceID:(NSString *)uuid;
+ (BOOL)isSimulatorID:(NSString *)uuid;

+ (NSString *)defaultSimulatorID;
+ (NSString *)defaultPhysicalDeviceIDEnsuringOnlyOneAttached:(BOOL)shouldThrow;
+ (NSString *)defaultDeviceID;
+ (NSArray<FBDevice *> *)availablePhysicalDevices;
+ (NSArray<FBSimulator *> *)availableSimulators;
+ (FBSimulator *)defaultSimulator:(NSArray<FBSimulator *>*)simulators;
@end
