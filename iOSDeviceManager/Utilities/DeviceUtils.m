#import "DeviceUtils.h"
#import "ConsoleWriter.h"

@interface NSString(Base64)
- (BOOL)isBase64;
@end

@implementation NSString(Base64)

- (BOOL)isBase64 {
    for (int i = 0; i < self.length; i++) {
        char c =  toupper([self characterAtIndex:i]);
        if (c < '0' || c > 'F') { return NO; }
    }
    return YES;
}
@end

@implementation DeviceUtils

const double EPSILON = 0.001;

+ (BOOL)isSimulatorID:(NSString *)did {
    return [[NSUUID alloc] initWithUUIDString:did] != nil;
}

+ (BOOL)isDeviceID:(NSString *)did {
    return did.length == 40 && [did isBase64];
}

+ (NSString *)findDeviceIDByName:(NSString *)name {

    for (FBDevice *device in [DeviceUtils availableDevices])
        if ([device.name isEqualToString:name])
            return device.udid;

    for (FBSimulator *simulator in [DeviceUtils availableSimulators])
        if ([simulator.name isEqualToString:name])
            return simulator.udid;

    return nil;
}


+ (NSArray<FBDevice *> *)availableDevices {
    static dispatch_once_t onceToken = 0;
    static NSArray<FBDevice *> *m_availableDevices;

    dispatch_once(&onceToken, ^{
        m_availableDevices = [[FBDeviceSet defaultSetWithLogger:nil error:nil] allDevices];
    });
    return m_availableDevices;
}


+ (NSArray<FBSimulator *> *)availableSimulators {
    static dispatch_once_t onceToken = 0;
    static NSArray<FBSimulator *> *m_availableSimulators;

    dispatch_once(&onceToken, ^{
        FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration
                                                      configurationWithDeviceSetPath:nil
                                                      options:FBSimulatorManagementOptionsIgnoreSpuriousKillFail];
    
        NSError *err;
        FBSimulatorControl *simControl = [FBSimulatorControl withConfiguration:configuration error:&err];
        if (err) {
            ConsoleWriteErr(@"Error creating FBSimulatorControl: %@", err);
            @throw [NSException exceptionWithName:@"GenericException"
                                       reason:@"Failed detecting available simulators"
                                     userInfo:nil];
        }

        m_availableSimulators = [[simControl set] allSimulators];
    });
    
    return m_availableSimulators;
}

+ (FBSimulator *)defaultSimulator:(NSArray<FBSimulator *>*)simulators {
    NSArray <FBSimulator *> *sorted = [simulators sortedArrayUsingComparator:^NSComparisonResult(id sim2, id sim1) {
        return [DeviceUtils comparePreferredSimulator:sim1 to:sim2];
    }];
    return [sorted firstObject];
}

+ (NSComparisonResult)comparePreferredSimulator:(FBSimulator *)sim to:(FBSimulator *)otherSim {
    NSDecimalNumber *simVersion = sim.configuration.os.number;
    NSDecimalNumber *otherSimVersion = otherSim.configuration.os.number;
    NSString *simDeviceName = [sim name];
    NSString *otherSimDeviceName = [otherSim name];
    
    if ([simVersion isGreaterThan:otherSimVersion]) {
        return NSOrderedDescending;
    } else if ([simVersion isEqual:otherSimVersion]) {
        if ([simDeviceName containsString:@"iPhone"] && [otherSimDeviceName containsString:@"iPhone"]) {
            NSCharacterSet *nonDigitCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
            NSString *simNumber = [[simDeviceName componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
            NSString *otherSimNumber = [[otherSimDeviceName componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
            if (simNumber.length == 0) {
                return NSOrderedAscending;
            }
            if (otherSimNumber.length == 0) {
                return NSOrderedSame;
            }
            if (fabs(simNumber.doubleValue - otherSimNumber.doubleValue) < EPSILON) {
                // Handle things like 6S vs 6
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".+\\d+[Ss]" options:0 error:nil];
                NSUInteger simIsS = [regex numberOfMatchesInString:simDeviceName options:0 range:NSMakeRange(0, [simDeviceName length])];
                NSUInteger otherSimIsS = [regex numberOfMatchesInString:otherSimDeviceName options:0 range:NSMakeRange(0, [otherSimDeviceName length])];

                if (simIsS > 0 && otherSimIsS == 0) {
                    return NSOrderedDescending;
                }
            } else if ((simNumber.doubleValue - otherSimNumber.doubleValue) > EPSILON) {
                return NSOrderedDescending;
            } else {
                return NSOrderedAscending;
            }
        } else if ([simDeviceName containsString:@"iPhone"] && ![otherSimDeviceName containsString:@"iPhone"]) {
            return NSOrderedDescending;
        }
    }
    
    return NSOrderedAscending;
}

+ (NSString *)defaultSimulatorID {
    NSArray<FBSimulator *> *sims = [DeviceUtils availableSimulators];
    return [DeviceUtils defaultSimulator:sims].udid;
}

+ (NSString *)defaultPhysicalDeviceIDEnsuringOnlyOneAttached:(BOOL)shouldThrow {
    NSArray<FBDevice *> *devices = [DeviceUtils availableDevices];
    
    if ([devices count] == 1) {
        return [devices firstObject].udid;
    } else if ([devices count] > 1) {
        ConsoleWriteErr(@"Multiple physical devices detected but none specified");
        if (shouldThrow) {
            @throw [NSException exceptionWithName:@"AmbiguousArgumentsException"
                                       reason:@"Multiple physical devices detected but none specified"
                                     userInfo:nil];
        }
        
        return [devices firstObject].udid;
    }
    
    return nil;
}

+ (NSString *)defaultDeviceID {
    
    NSString *physicalDeviceID = [self defaultPhysicalDeviceIDEnsuringOnlyOneAttached:YES];
    if (physicalDeviceID.length) {
        return physicalDeviceID;
    }
    
    NSString *simulatorDeviceID = [self defaultSimulatorID];
    if (simulatorDeviceID.length) {
        return simulatorDeviceID;
    }
    
    @throw [NSException exceptionWithName:@"MissingDeviceException"
                                   reason:@"Unable to determine default device"
                                 userInfo:nil];
}

@end
