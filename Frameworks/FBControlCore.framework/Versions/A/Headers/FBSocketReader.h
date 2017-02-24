/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <sys/socket.h>
#import <netinet/in.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSocketReaderDelegate;

/**
 A Reader of a Socket, passing input to a consumer.
 */
@interface FBSocketReader : NSObject

/**
 Creates and returns a socket reader for the provided port and consumer.

 @param port the port to bind against.
 @param delegate the delegate to use.
 @return a new socket reader.
 */
+ (instancetype)socketReaderOnPort:(in_port_t)port delegate:(id<FBSocketReaderDelegate>)delegate;

/**
 Create and Listen to the socket.

 @param error an error out for any error that occurs.
 @return YES if successful, NO otherwise.
 */
- (BOOL)startListeningWithError:(NSError **)error;

/**
 Stop listening to the socket

 @param error an error out for any error that occurs.
 @return YES if successful, NO otherwise.
 */
- (BOOL)stopListeningWithError:(NSError **)error;

@end

/**
 A consumer of a socket.
 */
@protocol FBSocketConsumer <NSObject>

/**
 Consumes Data from the Socket.

 @param data the data to consume.
 @return any data to be written back.
 */
- (nullable NSData *)consumeData:(NSData *)data;

@end

/**
 The Delegate for the Socket Reader
 */
@protocol FBSocketReaderDelegate <NSObject>

/**
 Create a consumer for the provided client.
 
 @param clientAddress the client address.
 @return a consumer of the socket.
 */
- (id<FBSocketConsumer>)consumerWithClientAddress:(struct in6_addr)clientAddress;

@end

NS_ASSUME_NONNULL_END
