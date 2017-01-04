#import <Foundation/Foundation.h>

@interface Application : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *bundleID;
@property (nonatomic, strong) NSDictionary *infoPlist;
@property (nonatomic, strong) NSArray<NSString *> *arches;

+ (Application *)withBundlePath:(NSString *)pathToBundle;

@end
