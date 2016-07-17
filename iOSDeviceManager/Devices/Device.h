
#import "TestParameters.h"
#import "iOSDeviceManagementCommand.h"
#import <Foundation/Foundation.h>

@interface Device : NSObject
+ (iOSReturnStatusCode)startTestOnDevice:(NSString *)deviceID
                          testRunnerPath:(NSString *)testRunnerPath
                          testBundlePath:(NSString *)testBundlePath
                        codesignIdentity:(NSString *)codesignIdentity
                        updateTestRunner:(BOOL)updateTestRunner
                               keepAlive:(BOOL)keepAlive; //helps with integration testing

+ (iOSReturnStatusCode)uninstallApp:(NSString *)bundleID
                           deviceID:(NSString *)deviceID;
+ (iOSReturnStatusCode)installApp:(NSString *)pathToBundle
                         deviceID:(NSString *)deviceID
                       codesignID:(NSString *)codesignID;
+ (iOSReturnStatusCode)appIsInstalled:(NSString *)bundleID
                             deviceID:(NSString *)deviceID;

+ (iOSReturnStatusCode)setLocation:(NSString *)deviceID
                               lat:(double)lat
                               lng:(double)lng;
@end
