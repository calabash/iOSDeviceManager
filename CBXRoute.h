
#import "Route.h"

@interface CBXRoute : Route
@property (nonatomic, strong)   NSString *HTTPVerb;
@property (nonatomic, strong)   NSString *path; //raw path
@property (nonatomic)       BOOL shouldAutoregister;

+ (instancetype)get:(NSString *)path withBlock:(RequestHandler)block;
+ (instancetype)post:(NSString *)path withBlock:(RequestHandler)block;
+ (instancetype)put:(NSString *)path withBlock:(RequestHandler)block;
+ (instancetype)delete:(NSString *)path withBlock:(RequestHandler)block;
@end
 
