
#import "TestParameters.h"
#import <Foundation/Foundation.h>

@interface Device : NSObject
+ (BOOL)startTest:(TestParameters *)params;
+ (BOOL)installApp:(NSString *)pathToBundle
          deviceID:(NSString *)deviceID
        codesignID:(NSString *)codesignID;
@end
