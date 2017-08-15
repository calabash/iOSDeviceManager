
#import <Foundation/Foundation.h>

typedef void(^filePathHandler)(NSString *filepath);

@interface FileUtils : NSObject
//Calls handler() on every file in dir, recursively. Depth first.
+ (void)fileSeq:(NSString *)dir handler:(filePathHandler)handler;
+ (NSArray<NSString *> *)depthFirstPathsStartingAtDirectory:(NSString *)dir
                                                      error:(NSError **)error;
+ (BOOL)isDylibOrFramework:(NSString *)objectPath;
+ (NSString *)expandPath:(NSString *)path;
@end
