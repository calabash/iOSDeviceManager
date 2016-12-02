
#import "iOSDeviceManagementCommand.h"
#import <Foundation/Foundation.h>

@interface CLI : NSObject
+ (iOSReturnStatusCode)process:(NSArray *)args;
@end
