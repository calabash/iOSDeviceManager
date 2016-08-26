
#import <Foundation/Foundation.h>

@class Certificate;
@class Entitlements;
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


- (NSString *)AppIDName;
- (NSArray<NSString *> *)ApplicationIdentifierPrefix;
- (NSArray<Certificate *> *)DeveloperCertificates;
- (Entitlements *)Entitlements;
- (NSArray<NSString *> *)ProvisionedDevices;
- (NSArray<NSString *> *)TeamIdentifier;
- (NSString *)UUID;
- (NSString *)TeamName;
- (NSString *)Name;
- (NSArray<NSString *> *)Platform;
- (NSDate *)ExpirationDate;
- (BOOL)isPlatformIOS;
- (BOOL)isExpired;
- (BOOL)containsDeviceUDID:(NSString *)deviceUDID;

@end