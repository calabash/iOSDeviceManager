#import "DeviceUtils.h"
#import "ConsoleWriter.h"
#import "SimDevice.h"
#import "XcodeUtils.h"

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
    return (did.length == 40 && [did isBase64]) || did.length == 25;
}

+ (FBDevice *)findDeviceByName:(NSString *)name {
    for (FBDevice *device in [DeviceUtils availableDevices]) {
        if ([device.name isEqualToString:name]) {
            return device;
        }
    }
    return nil;
}

+ (FBSimulator *)findSimulatorByName:(NSString *)name {
    NSString *instrumentsName;
    for (FBSimulator *simulator in [DeviceUtils availableSimulators]) {
        NSString *runtimeData = [(SimDevice *)simulator.device runtimeIdentifier];
        if (![runtimeData containsString:@"iOS"]) {
            // Ignore watches, tvs, and pairs.
            continue;
        }
        
        // Regex to extract version: com.apple.CoreSimulator.SimRuntime.iOS-12-1 => 12-1
        NSRegularExpression
        *regex = [NSRegularExpression
                  regularExpressionWithPattern:@"(\\d+)(-(\\d+))*"
                  options:0 error:nil];
        
        NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:runtimeData
                                     options:0 range:NSMakeRange(0, [runtimeData length])];

        if (NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
           continue;
        }
        
        // 12-1 => 12.1
        NSString *versionStr = [[runtimeData substringWithRange:rangeOfFirstMatch]
                                stringByReplacingOccurrencesOfString:@"-" withString:@"."];

        // 11 => 11.0
        // 12 => 12.0
        if (![versionStr containsString:@"."]) {
            versionStr = [versionStr stringByAppendingString:@".0"];
        }

        instrumentsName = [simulator.name stringByAppendingFormat:@" (%@)",
                           versionStr];

        if ([instrumentsName isEqualToString:name]) {
            return simulator;
        }
    }
    return nil;
}

+ (NSString *)findDeviceIDByName:(NSString *)name {
    FBDevice *device = [self findDeviceByName:name];
    if (device) return device.udid;
    FBSimulator *simulator = [self findSimulatorByName:name];
    if (simulator) return simulator.udid;
    return nil;
}

+ (NSArray<FBDevice *> *)availableDevices {
    static dispatch_once_t onceToken = 0;
    static NSArray<FBDevice *> *m_availableDevices;

    dispatch_once(&onceToken, ^{
        m_availableDevices = [[FBDeviceSet setWithLogger:FBControlCoreGlobalConfiguration.defaultLogger delegate:nil ecidFilter:nil error:nil] allDevices];
    });
    return m_availableDevices;
}


+ (NSArray<FBSimulator *> *)availableSimulators {
    static dispatch_once_t onceToken = 0;
    static NSArray<FBSimulator *> *m_availableSimulators;

    dispatch_once(&onceToken, ^{
        FBSimulatorControlConfiguration *configuration = [FBSimulatorControlConfiguration configurationWithDeviceSetPath:nil logger:nil reporter:nil];

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

+ (NSString *)defaultSimulatorID {
    NSString *simulatorName = [self defaultSimulator];
    FBSimulator *simulator = [self findSimulatorByName: simulatorName];
    if (simulator) {
        return simulator.udid;
    } else {
        [NSException raise: @"Non existing simulator"
                    format: @"Could not find default simulator: %@", simulatorName];
        return nil;
    }
};

+ (NSString *)defaultSimulator {
    NSUInteger major = XcodeUtils.versionMajor + 2;
    NSUInteger minor = XcodeUtils.versionMinor;

    if(XcodeUtils.versionMajor == 10 && XcodeUtils.versionMinor == 3){
        minor = 4;
    }
    
    NSString *deviceVersion;

    if (XcodeUtils.versionMajor == 11) {
        deviceVersion = @"11";
    } else if (XcodeUtils.versionMajor == 10) {
        if (XcodeUtils.versionMinor < 2) {
            deviceVersion = @"XS";
        } else {
            deviceVersion = @"Xs";
        }
    } else {
        deviceVersion = [NSString stringWithFormat: @"%lu", XcodeUtils.versionMajor - 1];
    }

    return [NSString
                stringWithFormat:@"iPhone %@ (%lu.%lu)",
                deviceVersion,
                major,
                minor];
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
