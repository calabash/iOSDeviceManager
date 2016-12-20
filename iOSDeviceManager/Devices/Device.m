
#import "PhysicalDevice.h"
#import "ShellRunner.h"
#import "Resources.h"
#import "Simulator.h"
#import "AppUtils.h"

@implementation Device

- (id)init {
    if (self = [super init]) {
        _testingComplete = NO;
    }
    return self;
}

+ (Device *)withID:(NSString *)uuid {
    if ([self isSimID:uuid]) { return [Simulator withID:uuid]; }
    if ([self isDeviceID:uuid]) { return [PhysicalDevice withID:uuid]; }
    @throw [NSException exceptionWithName:@"InvalidDeviceID"
                                   reason:@"Specified ID does not match simulator or device"
                                 userInfo:nil];
}

+ (BOOL)isSimID:(NSString *)uuid {
    
    if ([TestParameters isSimulatorID:uuid]) {
        return true;
    }
    
    return false;
}

+ (BOOL)isDeviceID:(NSString *)uuid {
    
    if ([TestParameters isDeviceID:uuid]) {
        return true;
    }
    
    return false;
}

+ (NSString *)defaultDeviceID {
    return [[Resources shared] defaultDeviceUDID] ?: [[Resources shared] defaultSimulatorUDID];
}

+ (void)initialize {
    const char *FBLog = [ShellRunner verbose] ? "YES" : "NO";
    setenv("FBCONTROLCORE_LOGGING", FBLog, 1);
    setenv("FBCONTROLCORE_DEBUG_LOGGING", FBLog, 1);
}

@end
