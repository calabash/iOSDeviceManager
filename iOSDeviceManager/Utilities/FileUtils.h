
#import <Foundation/Foundation.h>

typedef void(^filePathHandler)(NSString *filepath);

@interface FileUtils : NSObject
//Calls handler() on every file in dir, recursively. Depth first.
//Unlike clojure, `dir` must point to a real file or this method will throw up.  
+ (void)fileSeq:(NSString *)dir handler:(filePathHandler)handler;
+ (void)reverseFileSeq:(NSString *)dir handler:(filePathHandler)handler;
+ (BOOL)isDylibOrFramework:(NSString *)objectPath;
+ (NSString *)expandPath:(NSString *)path;
@end
