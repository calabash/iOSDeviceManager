
#import <Foundation/Foundation.h>
#import <XCTestBootstrap/XCTestBootstrap.h>

@interface Codesigner : NSObject  <FBCodesignProvider>

+ (Codesigner *)signerThatCannotSign;

- (instancetype)initWithCodeSignIdentity:(NSString *)codeSignIdentity
                              deviceUDID:(NSString *)deviceUDID;

- (NSString *)codeSignIdentity;
@end
