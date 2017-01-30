#import <Foundation/Foundation.h>
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>

@interface DeviceUtils : NSObject
+ (BOOL)isDeviceID:(NSString *)uuid;
+ (BOOL)isSimulatorID:(NSString *)uuid;

+ (NSString *)defaultSimulatorID;
+ (NSString *)defaultPhysicalDeviceID:(BOOL)ensureOneDevice;
+ (NSString *)defaultDeviceID;
+ (NSArray<FBDevice *> *)availableDevices;
+ (NSArray<FBSimulator *> *)availableSimulators;
+ (FBSimulator *)defaultSimulator:(NSArray<FBSimulator *>*)simulators;
@end
