#import <Foundation/Foundation.h>

@class CodesignIdentity;
@class MobileProfile;
@class Entitlements;

@interface BundleResigner : NSObject

@property(copy, readonly) NSString *bundlePath;
@property(copy, readonly) NSString *deviceUDID;
@property(strong, readonly) CodesignIdentity *identity;
@property(strong, readonly) MobileProfile *mobileProfile;
@property(strong, readonly) Entitlements *originalEntitlements;

- (instancetype)initWithBundlePath:(NSString *)bundlePath
              originalEntitlements:(Entitlements *)originalEntitlements
                          identity:(CodesignIdentity *)identity
                     mobileProfile:(MobileProfile *)mobileProfile
                        deviceUDID:(NSString *)deviceUDID;

- (BOOL)resign;

@end