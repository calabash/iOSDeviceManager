//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Nov 26 2020 14:08:26).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <DTXConnectionServices/NSObject-Protocol.h>

@class DTXMessage, NSString;
@protocol DTXAllowedRPC;

@protocol DTXMessenger <NSObject>
- (void)cancel;
@property(copy, nonatomic) NSString *label;
- (void)registerDisconnectHandler:(void (^)(void))arg1;
- (void)sendControlAsync:(DTXMessage *)arg1 replyHandler:(void (^)(DTXMessage *))arg2;
- (void)sendControlSync:(DTXMessage *)arg1 replyHandler:(void (^)(DTXMessage *))arg2;
- (void)sendMessage:(DTXMessage *)arg1 replyHandler:(void (^)(DTXMessage *))arg2;
- (BOOL)sendMessageAsync:(DTXMessage *)arg1 replyHandler:(void (^)(DTXMessage *))arg2;
- (void)sendMessageSync:(DTXMessage *)arg1 replyHandler:(void (^)(DTXMessage *))arg2;
- (void)setDispatchTarget:(id <DTXAllowedRPC>)arg1;
- (void)setMessageHandler:(void (^)(DTXMessage *))arg1;
@end

