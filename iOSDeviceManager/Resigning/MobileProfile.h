
#import "Entitlements.h"

@class Certificate;
@class CodesignIdentity;

@interface MobileProfile : NSObject

@property(copy, readonly) NSDictionary *info;
@property(copy, readonly) NSString *path;

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

- (NSString *)AppIDName;
- (NSArray<NSString *> *)applicationIdentifierPrefix;
- (NSArray<Certificate *> *)developerCertificates;
- (Entitlements *)entitlements;
- (NSArray<NSString *> *)ProvisionedDevices;
- (NSArray<NSString *> *)TeamIdentifier;
- (NSString *)uuid;
- (NSString *)TeamName;
- (NSString *)name;
- (NSArray<NSString *> *)Platform;
- (NSDate *)ExpirationDate;
- (BOOL)isPlatformIOS;
- (BOOL)isExpired;
- (BOOL)containsDeviceUDID:(NSString *)deviceUDID;

@end
