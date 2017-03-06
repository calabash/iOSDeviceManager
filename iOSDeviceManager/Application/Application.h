#import <Foundation/Foundation.h>

typedef NS_ENUM(short, ApplicationType) {
    kApplicationTypeUnknown = -1,
    kApplicationTypeNone = 0,
    kApplicationTypePhysicalDevice,
    kApplicationTypeSimulator
};

@interface Application : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *bundleID;
@property (nonatomic, strong) NSDictionary *infoPlist;
@property (nonatomic, strong) NSSet<NSString *> *arches;
@property (nonatomic)       ApplicationType type;

/**
    Returns the path to the directory containing the application bundle.
    For .ipas, this will be two levels up.
    For simulator apps, this will be the immediate parent directory.
 */
- (NSString *)baseDir;
+ (Application *)withBundlePath:(NSString *)pathToBundle;
+ (Application *)withBundleID:(NSString *)bundleID plist:(NSDictionary *)plist architectures:(NSSet *)architectures;

@end
