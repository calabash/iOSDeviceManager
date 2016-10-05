
#import <Foundation/Foundation.h>
#import <XCTestBootstrap/XCTestBootstrap.h>

@interface Codesigner : NSObject  <FBCodesignProvider>

+ (Codesigner *)signerThatCannotSign;

- (instancetype)initWithCodeSignIdentity:(NSString *)codeSignIdentity
                              deviceUDID:(NSString *)deviceUDID;

- (instancetype)initAdHocWithDeviceUDID:(NSString *)deviceUDID;

- (BOOL)signBundleAtPath:(NSString *)bundlePath
                   error:(NSError **)error;

- (BOOL)validateSignatureAtBundlePath:(NSString *)bundlePath;

- (NSString *)codeSignIdentity;
@end
