
#import "LaunchAppCommand.h"
#import "PhysicalDevice.h"

static NSString *const BUNDLE_ID_FLAG = @"-b";
static NSString *const DEVICE_ID_FLAG = @"-d";
static NSString *const APPARGUMENTS_ID_FLAG = @"-a";
static NSString *const APPENVIRONMENT_ID_FLAG = @"-e";

@implementation LaunchAppCommand
+ (NSString *)name {
    return @"launch_app";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    NSString *appArgs = [self optionDict][APPARGUMENTS_ID_FLAG].defaultValue;
    if ([args.allKeys containsObject:APPARGUMENTS_ID_FLAG]) {
        appArgs = args[APPARGUMENTS_ID_FLAG];
    }
    
    NSString *appEnv = [self optionDict][APPENVIRONMENT_ID_FLAG].defaultValue;
    if ([args.allKeys containsObject:APPENVIRONMENT_ID_FLAG]) {
        appEnv = args[APPENVIRONMENT_ID_FLAG];
    }
    
    return [PhysicalDevice launchApp:args[BUNDLE_ID_FLAG] appArgs:appArgs
                                                           appEnv:appEnv
                                                         deviceID:args[DEVICE_ID_FLAG]];
}

@end
