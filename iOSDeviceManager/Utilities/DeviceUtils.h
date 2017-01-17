
#import <Foundation/Foundation.h>

@interface DeviceUtils : NSObject
+ (BOOL)isDeviceID:(NSString *)uuid;
+ (BOOL)isSimulatorID:(NSString *)uuid;
@end
