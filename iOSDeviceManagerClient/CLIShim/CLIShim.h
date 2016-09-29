
#import <Foundation/Foundation.h>
#import "ServerConfig.h"

@interface CLIShim : NSObject
+ (iOSReturnStatusCode)process:(NSArray <NSString *> *)args;
@end
