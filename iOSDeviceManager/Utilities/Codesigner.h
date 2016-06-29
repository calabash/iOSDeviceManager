
#import <Foundation/Foundation.h>
#import <XCTestBootstrap/XCTestBootstrap.h>

@interface Codesigner : NSObject  <FBCodesignProvider>
@property (nonatomic, strong) NSString *codesignIdentity;
@end
