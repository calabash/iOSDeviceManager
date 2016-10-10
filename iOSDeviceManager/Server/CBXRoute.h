//
//  CBRoute.h
//  xcuitest-server
//

#import "Route.h"

/**
Object containing logic for an HTTP route. 
 
 Routes respond to a particular verb for a particular path regex 
 and invoke a RequestHandler based on the client request.
 */
@interface CBXRoute : Route
@property (nonatomic, strong)   NSString *HTTPVerb;
@property (nonatomic, strong)   NSString *path; //raw path

/**
 Boolean value (defaults to YES) which indicates that a route
 should automatically register itself with the HTTP server for requests. 
 
 Generally this is more convenient for development, as you don't need to 
 manually add every new route to the http server. However, you might 
 want to override this in cases when the regex of a route will overshadow
 other routes and you want more control of the order. 
 
 See UndefinedRoutes
 */
@property (nonatomic)       BOOL shouldAutoregister;

/**
 Convenience constructor for a GET route
 @param path Route path regex
 @param block Block to execude when requests are matched to this route
 */
+ (instancetype)get:(NSString *)path withBlock:(RequestHandler)block;

/**
 Convenience constructor for a POST route
 @param path Route path regex
 @param block Block to execude when requests are matched to this route
 */
+ (instancetype)post:(NSString *)path withBlock:(RequestHandler)block;

/**
 Convenience constructor for a PUT route
 @param path Route path regex
 @param block Block to execude when requests are matched to this route
 */
+ (instancetype)put:(NSString *)path withBlock:(RequestHandler)block;

/**
 Convenience constructor for a DELETE route
 @param path Route path regex
 @param block Block to execude when requests are matched to this route
 */
+ (instancetype)delete:(NSString *)path withBlock:(RequestHandler)block;
@end
 