
#import <Foundation/Foundation.h>
#import "CodesignIdentity.h"
#import "BundleResigner.h"

@interface BundleResignerFactory : NSObject

+ (nonnull BundleResignerFactory *)shared;

- (nullable BundleResigner *)resignerWithBundlePath:(nonnull NSString *)bundlePath
                                         deviceUDID:(nonnull NSString *)deviceUDID
                              signingIdentityString:(nullable NSString *)signingIdentityOrNil;

- (nullable BundleResigner *)resignerWithBundlePath:(nonnull NSString *)bundlePath
                                         deviceUDID:(nonnull NSString *)deviceUDID
                                           identity:(nonnull CodesignIdentity *)signingIdentityOrNil;

- (nullable BundleResigner *)adHocResignerWithBundlePath:(nonnull NSString *)bundlePath
                                              deviceUDID:(nonnull NSString *)deviceUDID;

@end
