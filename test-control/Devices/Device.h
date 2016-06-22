
#import "TestParameters.h"
#import <Foundation/Foundation.h>

@interface Device : NSObject
+ (BOOL)startTest:(TestParameters *)params;
+ (BOOL)uninstallApp:(NSString *)bundleID
            deviceID:(NSString *)deviceID;
+ (BOOL)installApp:(NSString *)pathToBundle
          deviceID:(NSString *)deviceID
        codesignID:(NSString *)codesignID;
+ (int)appIsInstalled:(NSString *)bundleID
             deviceID:(NSString *)deviceID;
+ (BOOL)clearAppData:(NSString *)bundleID
            deviceID:(NSString *)deviceID;
@end
