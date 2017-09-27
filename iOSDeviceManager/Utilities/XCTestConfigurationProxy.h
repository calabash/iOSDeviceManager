
#import <Foundation/Foundation.h>

@interface XCTestConfigurationProxy : NSObject

@property(strong) id configuration;

+ (XCTestConfigurationProxy *)configurationWithContentsOfFile:(NSString *)path;

- (BOOL)writeToPlistFile:(NSString *)path overwrite:(BOOL)overwrite;

@end
