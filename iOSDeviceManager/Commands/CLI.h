

#import <Foundation/Foundation.h>
#import "iOSReturnStatusCode.h"

@interface CLI : NSObject
+ (iOSReturnStatusCode)process:(NSArray *)args;
@end
