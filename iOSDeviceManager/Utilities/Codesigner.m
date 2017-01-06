
#import "Codesigner.h"
#import "BundleResignerFactory.h"
#import "BundleResigner.h"
#import "iOSDeviceManagementCommand.h"
#import "Device.h"

static NSString *const IDMCodeSignErrorDomain = @"sh.calaba.iOSDeviceManger";

@interface Codesigner ()

@property(copy) NSString *codeSignIdentity;
@property(copy) NSString *deviceUDID;

@end

@implementation Codesigner

+ (Codesigner *)signerThatCannotSign {
    return [Codesigner new];
}

@synthesize codeSignIdentity = _codeSignIdentity;
@synthesize deviceUDID = _deviceUDID;

- (instancetype)initWithCodeSignIdentity:(NSString *)codeSignIdentity
                              deviceUDID:(NSString *)deviceUDID {
    self = [super init];
    if (self) {
        _codeSignIdentity = codeSignIdentity;
        _deviceUDID = deviceUDID;
    }
    return self;
}

- (instancetype)initAdHocWithDeviceUDID:(NSString *)deviceUDID {
    self = [super init];
    if (self) {
        _codeSignIdentity = nil;
        _deviceUDID = deviceUDID;
    }
    return self;
}

- (NSString *)description {
    if (self.codeSignIdentity && self.deviceUDID) {
        return [NSString stringWithFormat:@"#<Codesigner %@ : %@>",
                self.deviceUDID, self.codeSignIdentity];
    } else {
        return @"#<Codesigner *** CANNOT CODESIGN ***>";
    }
}

- (BOOL)signBundleAtPath:(NSString *)bundlePath
                   error:(NSError **)error {
    NSAssert(self.deviceUDID != nil,
             @"Can not have a codesign command without a device");

    BundleResigner *resigner = [self bundleResignerForBundleAtPath:bundlePath];

    if (!resigner) {
        if (error) {
            NSString *description = @"Could not resign with the given arguments";
            NSString *reason = @"The device UDID and code signing identity were invalid for"
            "some reason.  Please check the logs.";
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description,
                                       NSLocalizedFailureReasonErrorKey: reason
                                       };

            *error = [NSError errorWithDomain:IDMCodeSignErrorDomain
                                         code:iOSReturnStatusCodeInternalError
                                     userInfo:userInfo];
        }
        return NO;
    }

    BOOL success;
    if ([Device isDeviceID:self.deviceUDID]) {
        success = [resigner resign];
    } else {
        success = [resigner resignSimBundle];
    }

    if (!success) {
        if (error) {
            NSString *description = @"Code signing failed";
            NSString *reason = @"There was a problem code signing. Please check the logs.";
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description,
                                       NSLocalizedFailureReasonErrorKey: reason
                                       };

            *error = [NSError errorWithDomain:IDMCodeSignErrorDomain
                                         code:iOSReturnStatusCodeInternalError
                                     userInfo:userInfo];
        }
        return NO;
    }

    return success;
}

- (BOOL)validateSignatureAtBundlePath:(NSString *)bundlePath {
    BundleResigner *resigner = [self bundleResignerForBundleAtPath:bundlePath];
    return resigner && [resigner validateBundleSignature];
}

- (BundleResigner *)bundleResignerForBundleAtPath:(NSString *)bundlePath {
    BundleResigner *resigner;
    if ([Device isDeviceID:self.deviceUDID]) {
        resigner = [[BundleResignerFactory shared] resignerWithBundlePath:bundlePath
                                                               deviceUDID:self.deviceUDID
                                                    signingIdentityString:self.codeSignIdentity];
    } else {
        resigner = [[BundleResignerFactory shared] adHocResignerWithBundlePath:bundlePath
                                                                    deviceUDID:self.deviceUDID];
    }

    return resigner;
}

@end
