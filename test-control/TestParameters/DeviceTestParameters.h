
#import <Foundation/Foundation.h>

#import "TestParameters.h"

@interface DeviceTestParameters : TestParameters
@property (nonatomic, strong) NSString *workingDirectory;
@property (nonatomic, strong) NSString *pathToXcodePlatformDir;
@property (nonatomic, strong) NSString *applicationDataPath;
@property (nonatomic, strong) NSString *codesignIdentity;
@end
