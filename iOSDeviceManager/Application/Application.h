#import <Foundation/Foundation.h>

@interface Application : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *bundleID;
@property (nonatomic, strong) NSDictionary *infoPlist;
@property (nonatomic, strong) NSSet<NSString *> *arches;

+ (Application *)withBundlePath:(NSString *)pathToBundle;
+ (Application *)withBundleID:(NSString *)bundleID plist:(NSDictionary *)plist architectures:(NSSet *)architectures;

@end
