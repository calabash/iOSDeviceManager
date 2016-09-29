#import "RoutingHTTPServer.h"
#import "RoutingConnection.h"
#import "CBXMacros.h"
#import "CBXRoute.h"

@implementation RoutingHTTPServer {
	NSMutableDictionary *routes;
	NSMutableDictionary *defaultHeaders;
	NSMutableDictionary *mimeTypes;
	dispatch_queue_t routeQueue;
}

@synthesize defaultHeaders;

- (id)init {
	if (self = [super init]) {
		connectionClass = [RoutingConnection self];
		routes = [[NSMutableDictionary alloc] init];
		defaultHeaders = [[NSMutableDictionary alloc] init];
		[self setupMIMETypes];
	}
	return self;
}

#if !OS_OBJECT_USE_OBJC_RETAIN_RELEASE
- (void)dealloc {
	if (routeQueue)
		dispatch_release(routeQueue);
}
#endif

- (void)setDefaultHeaders:(NSDictionary *)headers {
	if (headers) {
		defaultHeaders = [headers mutableCopy];
	} else {
		defaultHeaders = [[NSMutableDictionary alloc] init];
	}
}

- (void)setDefaultHeader:(NSString *)field value:(NSString *)value {
	[defaultHeaders setObject:value forKey:field];
}

// For testing that routes are loaded.
- (NSDictionary *)routes {
    return [NSDictionary dictionaryWithDictionary:routes];
}

- (dispatch_queue_t)routeQueue {
	return routeQueue;
}

- (void)setRouteQueue:(dispatch_queue_t)queue {
#if !OS_OBJECT_USE_OBJC_RETAIN_RELEASE
	if (queue)
		dispatch_retain(queue);

	if (routeQueue)
		dispatch_release(routeQueue);
#endif

	routeQueue = queue;
}

- (NSDictionary *)mimeTypes {
	return mimeTypes;
}

- (void)setMIMETypes:(NSDictionary *)types {
	NSMutableDictionary *newTypes;
	if (types) {
		newTypes = [types mutableCopy];
	} else {
		newTypes = [[NSMutableDictionary alloc] init];
	}

	mimeTypes = newTypes;
}

- (void)setMIMEType:(NSString *)theType forExtension:(NSString *)ext {
	[mimeTypes setObject:theType forKey:ext];
}

- (NSString *)mimeTypeForPath:(NSString *)path {
	NSString *ext = [[path pathExtension] lowercaseString];
	if (!ext || [ext length] < 1)
		return nil;

	return [mimeTypes objectForKey:ext];
}

- (void)get:(NSString *)path withBlock:(RequestHandler)block {
	[self handleMethod:@"GET" withPath:path block:block];
}

- (void)post:(NSString *)path withBlock:(RequestHandler)block {
	[self handleMethod:@"POST" withPath:path block:block];
}

- (void)put:(NSString *)path withBlock:(RequestHandler)block {
	[self handleMethod:@"PUT" withPath:path block:block];
}

- (void)delete:(NSString *)path withBlock:(RequestHandler)block {
	[self handleMethod:@"DELETE" withPath:path block:block];
}

- (void)handleMethod:(NSString *)method withPath:(NSString *)path block:(RequestHandler)block {
	Route *route = [Route routeWithPath:path block:block];
	[self addRoute:route forMethod:method];
}

- (void)handleMethod:(NSString *)method withPath:(NSString *)path target:(id)target selector:(SEL)selector {
    Route *route = [Route routeWithPath:path target:target selector:selector];

	[self addRoute:route forMethod:method];
}

- (void)addRoute:(CBXRoute *)route {
    NSLog(@"Adding route: %@", route);
    [self addRoute:route forMethod:route.HTTPVerb];
}

- (void)addRoute:(Route *)route forMethod:(NSString *)method {
    
	method = [method uppercaseString];
	NSMutableArray *methodRoutes = [routes objectForKey:method];
	if (methodRoutes == nil) {
		methodRoutes = [NSMutableArray array];
		[routes setObject:methodRoutes forKey:method];
	}

	[methodRoutes addObject:route];

	// Define a HEAD route for all GET routes
	if ([method isEqualToString:@"GET"]) {
		[self addRoute:route forMethod:@"HEAD"];
	}
}

- (BOOL)supportsMethod:(NSString *)method {
	return ([routes objectForKey:method] != nil);
}

- (void)handleRoute:(Route *)route withRequest:(RouteRequest *)request response:(RouteResponse *)response {
	if (route.handler) {
		route.handler(request, DATA_TO_JSON(request.body), response);
	} else {
		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[route.target performSelector:route.selector withObject:request withObject:response];
		#pragma clang diagnostic pop
	}
}

- (RouteResponse *)routeMethod:(NSString *)method withPath:(NSString *)path parameters:(NSDictionary *)params request:(HTTPMessage *)httpMessage connection:(HTTPConnection *)connection {
	NSMutableArray *methodRoutes = [routes objectForKey:method];
	if (methodRoutes == nil)
		return nil;

	for (Route *route in methodRoutes) {
		NSTextCheckingResult *result = [route.regex firstMatchInString:path options:0 range:NSMakeRange(0, path.length)];
		if (!result)
			continue;

		// The first range is all of the text matched by the regex.
		NSUInteger captureCount = [result numberOfRanges];

		if (route.keys) {
			// Add the route's parameters to the parameter dictionary, accounting for
			// the first range containing the matched text.
			if (captureCount == [route.keys count] + 1) {
				NSMutableDictionary *newParams = [params mutableCopy];
				NSUInteger index = 1;
				BOOL firstWildcard = YES;
				for (NSString *key in route.keys) {
					NSString *capture = [path substringWithRange:[result rangeAtIndex:index]];
					if ([key isEqualToString:@"wildcards"]) {
						NSMutableArray *wildcards = [newParams objectForKey:key];
						if (firstWildcard) {
							// Create a new array and replace any existing object with the same key
							wildcards = [NSMutableArray array];
							[newParams setObject:wildcards forKey:key];
							firstWildcard = NO;
						}
						[wildcards addObject:capture];
					} else {
						[newParams setObject:capture forKey:key];
					}
					index++;
				}
				params = newParams;
			}
		} else if (captureCount > 1) {
			// For custom regular expressions place the anonymous captures in the captures parameter
			NSMutableDictionary *newParams = [params mutableCopy];
			NSMutableArray *captures = [NSMutableArray array];
			for (NSUInteger i = 1; i < captureCount; i++) {
				[captures addObject:[path substringWithRange:[result rangeAtIndex:i]]];
			}
			[newParams setObject:captures forKey:@"captures"];
			params = newParams;
		}

		RouteRequest *request = [[RouteRequest alloc] initWithHTTPMessage:httpMessage parameters:params];
		RouteResponse *response = [[RouteResponse alloc] initWithConnection:connection];
		if (!routeQueue) {
			[self handleRoute:route withRequest:request response:response];
		} else {
			// Process the route on the specified queue
			dispatch_sync(routeQueue, ^{
				@autoreleasepool {
                    NSString *path = [route.regex description];
                    if ([route isKindOfClass:[CBXRoute class]]) {
                        path = ((CBXRoute *)route).path;
                    }
                    NSLog(@"%@ %@ %@", request.method, path, DATA_TO_JSON(request.body) ?: @"");
					[self handleRoute:route withRequest:request response:response];
				}
			});
		}
		return response;
	}

	return nil;
}

- (void)setupMIMETypes {
	mimeTypes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
				 @"application/x-javascript",   @"js",
				 @"image/gif",                  @"gif",
				 @"image/jpeg",                 @"jpg",
				 @"image/jpeg",                 @"jpeg",
				 @"image/png",                  @"png",
				 @"image/svg+xml",              @"svg",
				 @"image/tiff",                 @"tif",
				 @"image/tiff",                 @"tiff",
				 @"image/x-icon",               @"ico",
				 @"image/x-ms-bmp",             @"bmp",
				 @"text/css",                   @"css",
				 @"text/html",                  @"html",
				 @"text/html",                  @"htm",
				 @"text/plain",                 @"txt",
				 @"text/xml",                   @"xml",
				 nil];
}

@end
