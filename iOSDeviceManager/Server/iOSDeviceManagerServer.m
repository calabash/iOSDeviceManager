
#import "iOSDeviceManagerServer.h"
#import "RoutingHTTPServer.h"
#import "RoutingConnection.h"
#import "CBXRoute.h"
#import "CLI.h"

@interface iOSDeviceManagerServer ()
@end

@implementation iOSDeviceManagerServer

static NSString *const iOSDeviceManagerServerDomain = @"sh.calaba.iOSDeviceManager-server";
static NSString *const serverName = @"iOSDeviceManagerServer";
static BOOL alive = YES;

+ (RoutingHTTPServer *)router {
    static RoutingHTTPServer *server = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        server = [RoutingHTTPServer new];
        [server setRouteQueue:dispatch_get_main_queue()];
        [server setDefaultHeader:@"CalabusDriver"
                           value:@"CalabashXCUITestServer/1.0"];
        [server setConnectionClass:[RoutingConnection class]];
        [server setType:@"_iOSDeviceManagerServer._tcp."];
        [server setPort:SERVER_PORT];
        
        NSString *uuid = [[NSProcessInfo processInfo] globallyUniqueString];
        NSString *token = [uuid componentsSeparatedByString:@"-"][0];
        NSString *serverName = [NSString stringWithFormat:@"iOSDeviceManagerServer-%@", token];
        [server setName:serverName];
        [server addRoute:[self cliRoute]];
        [server addRoute:[self healthRoute]];
        [server addRoute:[self killRoute]];
    });

    return server;
}

+ (CBXRoute *)cliRoute {
    return [CBXRoute post:@"/cli" withBlock:^(RouteRequest *request, id args, RouteResponse *response) {
        [response respondWithJSON:@{@"exit_code" : @([CLI process:args])}];
    }];
}

+ (CBXRoute *)healthRoute {
    return [CBXRoute get:@"/health" withBlock:^(RouteRequest *request, NSDictionary *body, RouteResponse *response) {
        [response respondWithJSON:@{@"status" : @"Reportin' for duty."}];
    }];
}

+ (CBXRoute *)killRoute {
    return [CBXRoute get:@"/kill" withBlock:^(RouteRequest *request, NSDictionary *body, RouteResponse *response) {
        [response respondWithJSON:@{@"status" : @"Exiting..."}];
        alive = NO;
    }];
}

+ (BOOL)attemptToStartWithError:(NSError **)error {
    NSError *innerError = nil;
    BOOL started = [self.router start:&innerError];
    if (!started) {
        if (!error) {
            return NO;
        }
        
        NSString *description = @"Unknown Error when Starting server";
        if ([innerError.domain isEqualToString:NSPOSIXErrorDomain] && innerError.code == EADDRINUSE) {
            description = [NSString stringWithFormat:@"Unable to start web server on port %ld", (long)self.router.port];
        }
        
        *error = [NSError errorWithDomain:iOSDeviceManagerServerDomain
                                     code:0
                                 userInfo:@{NSLocalizedDescriptionKey : description,
                                            NSUnderlyingErrorKey : innerError}];
        return NO;
    }
    return YES;
}

+ (void)start {
    NSError *error;
    BOOL serverStarted = NO;

    NSLog(@"Attempting to start the iOSDeviceManager server");
    serverStarted = [self attemptToStartWithError:&error];
    
    if (!serverStarted) {
        NSLog(@"Attempt to start web server failed with error %@", [error description]);
        abort();
    }
    
    NSLog(@"%@ started on http://localhost:%hu",
          serverName,
          [self.router port]);
    
    while (alive) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}
@end
