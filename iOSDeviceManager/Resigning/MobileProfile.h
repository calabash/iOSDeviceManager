
#import "Entitlements.h"
#import "Application.h"
#import "Certificate.h"
#import "Device.h"

@interface MobileProfile : NSObject

@property(copy, readonly) NSDictionary *info;
@property(copy, readonly) NSString *path;

+ (MobileProfile *)bestMatchProfileForApplication:(Application *)app device:(Device *)device;

+ (NSArray<MobileProfile *> *)nonExpiredIOSProfiles;
+ (NSArray<MobileProfile *> *)rankedProfiles:(NSArray<MobileProfile *> *)mobileProfiles
                                withIdentity:(CodesignIdentity *)identity
                                  deviceUDID:(NSString *)deviceUDID
                               appBundlePath:(NSString *)appBundlePath;

// TODO: Apply this to the algorithm
+ (MobileProfile *)embeddedMobileProvision:(NSString *)appBundle
                                  identity:(CodesignIdentity *)identity
                                deviceUDID:(NSString *)deviceUDID;

- (BOOL)isValidForDeviceUDID:(NSString *)deviceUDID
                    identity:(CodesignIdentity *)identity;

- (NSString *)appIDName;
- (NSArray<NSString *> *)applicationIdentifierPrefix;
- (NSArray<Certificate *> *)developerCertificates;
- (Entitlements *)entitlements;
- (NSArray<NSString *> *)provisionedDevices;
- (NSArray<NSString *> *)teamIdentifier;
- (NSString *)uuid;
- (NSString *)teamName;
- (NSString *)name;
- (NSArray<NSString *> *)platform;
- (NSDate *)expirationDate;
- (BOOL)isPlatformIOS;
- (BOOL)isExpired;
- (BOOL)containsDeviceUDID:(NSString *)deviceUDID;

/*
    Profiles can contain many identities. This is a convenience method
    to grab a reference to a valid identity within a given profile.
 */
- (CodesignIdentity *)findValidIdentity;

@end
