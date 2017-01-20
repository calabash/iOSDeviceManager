
#import <Foundation/Foundation.h>

typedef void(^filePathHandler)(NSString *filepath);

@interface FileUtils : NSObject
//Calls handler() on every file in dir, recursively. Depth first. 
+ (void)fileSeq:(NSString *)dir handler:(filePathHandler)handler;

+ (BOOL)isDylibOrFramework:(NSString *)objectPath;
@end
