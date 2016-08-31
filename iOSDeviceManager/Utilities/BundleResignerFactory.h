
#import <Foundation/Foundation.h>

@class BundleResigner;
@class CodesignIdentity;

@interface BundleResignerFactory : NSObject

+ (nonnull BundleResignerFactory *)shared;

- (nullable BundleResigner *)resignerWithBundlePath:(nonnull NSString *)bundlePath
                                         deviceUDID:(nonnull NSString *)deviceUDID
                              signingIdentityString:(nullable NSString *)signingIdentityOrNil;

- (nullable BundleResigner *)resignerWithBundlePath:(nonnull NSString *)bundlePath
                                         deviceUDID:(nonnull NSString *)deviceUDID
                                           identity:(nonnull CodesignIdentity *)signingIdentityOrNil;

@end
