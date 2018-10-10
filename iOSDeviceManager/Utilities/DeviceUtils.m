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

    for (FBDevice *device in [DeviceUtils availableDevices]) {
        if ([device.name isEqualToString:name]) {
            return device.udid;
        }
    }

    NSString *instrumentsName;
    for (FBSimulator *simulator in [DeviceUtils availableSimulators]) {
        FBOSVersion *version = simulator.osVersion;
        if (![version.name containsString:@"iOS"]) {
            // Ignore watches, tvs, and pairs.
            continue;
        }

        NSString *versionStr = [NSString stringWithFormat:@"%@", version.number];

        // 11 => 11.0
        // 12 => 12.0
        if (![versionStr containsString:@"."]) {
            versionStr = [versionStr stringByAppendingString:@".0"];
        }

        instrumentsName = [simulator.name stringByAppendingFormat:@" (%@)",
                           versionStr];

        if ([instrumentsName isEqualToString:name]) {
            return simulator.udid;
        }
    }

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

+ (void) getXcodeVersionTo:(int *)major and:(int*) minor{
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"-c", @"xcrun xcodebuild -version"];
    task.standardOutput = pipe;
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    
    NSString *str = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Xcode\\s+(\\d+)\\.(\\d+)" options:0 error:nil];
    
    NSArray *matches = [regex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
    
    NSString *j = [str substringWithRange:[(NSTextCheckingResult*)matches[0] rangeAtIndex:1]];
    NSString *i = [str substringWithRange:[(NSTextCheckingResult*)matches[0] rangeAtIndex:2]];
    *major = j.intValue;
    *minor = i.intValue;
}

+ (FBSimulator *)defaultSimulator:(NSArray<FBSimulator *>*)simulators {
    // step 1. define desired simulator model and runtime
    int xcode_major;
    int xcode_minor;
    [self getXcodeVersionTo:&xcode_major and:&xcode_minor];
    // TODO: runtime versionwill be used in iOS version comparision
    // int major=xcode_major+2;
    // int minor=xcode_minor;
    
    NSString *defaultModel;
    
    if (xcode_major == 10) {
        defaultModel=@"XS";
    }else{
        defaultModel=[NSString stringWithFormat:@"%d", xcode_major-1];
    }
    
    // step 2. find FBSimulator with the desired simulators
    // Re explanation:
    //   iPhone\\s+  - skip anything before model name
    //   (\\d+|XS)   - pickup either XS or one of 4..8 model
    //                 and save it into capture group #1
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"iPhone\\s+(\\d+|XS)"
                                  options:0 error:nil];
    
    // while we do not have iOS information will assign each matched simulator
    // to "def" variable. The last one will be returned
    FBSimulator *defaultSimulatorCandidate = nil;
    for (FBSimulator *simulator in simulators) {
        NSString *simName = [simulator name];
        NSArray *matches = [regex matchesInString:simName options:0 range:NSMakeRange(0, [simName length])];
        if (!matches || matches.count == 0) {
            continue;
        }
        // rangeAtIndex:0 - the whole match
        // rangeAtIndex:1 - the first captured group #1
        NSString *model = [simName substringWithRange:[(NSTextCheckingResult*)matches[0] rangeAtIndex:1]];
        if ([model isEqualToString:defaultModel]) {
            defaultSimulatorCandidate=simulator;
        }else{
            continue;
        }
    }
    return defaultSimulatorCandidate;
};

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
