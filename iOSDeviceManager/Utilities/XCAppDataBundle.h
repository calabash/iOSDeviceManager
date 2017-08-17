
#import <Foundation/Foundation.h>

@interface XCAppDataBundle : NSObject

+ (BOOL)isValid:(NSString *)expanded;
+ (BOOL)generateBundleSkeleton:(NSString *)path
                          name:(NSString *) name
                     overwrite:(BOOL)overwrite;

+ (NSArray *)sourceDirectoriesForSimulator:(NSString *)path;

@end
