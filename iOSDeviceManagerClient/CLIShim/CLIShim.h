
#import <Foundation/Foundation.h>
#import "iOSDeviceManagementCommand.h"

@interface CLIShim : NSObject
+ (iOSReturnStatusCode)process:(NSArray <NSString *> *)args;
@end
