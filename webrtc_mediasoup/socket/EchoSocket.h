//
//  EchoSocket.h
//  webrtc_mediasoup
//
//  Created by JH on 2020/4/25.
//  Copyright © 2020 JH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MessageObserver.h"

NS_ASSUME_NONNULL_BEGIN

@protocol EchoSocketDelegate <NSObject>

- (void)webSocketDidOpen;

@end

@interface EchoSocket : NSObject

@property (nonatomic, weak) id<EchoSocketDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)url registerObserver:(id<MessageObserver>) observer;
-(void)registerObserver:(id<MessageObserver>) observer ;

-(void)unRegisterObserver:(id<MessageObserver>) observer;

-(void)sendMethod:(NSString *)method body:(NSDictionary *)dic requestId:(NSString *)requestId;

-(void)sendMethod:(NSString *)method body:(NSDictionary *)dic;


//发送同步消息，很多操作要同步
- (void)sendWithAckMethod:(NSString *)method
             body:(NSDictionary *)dic
completionHandler:(AckCallHandler)completionHandler;

@end


@interface AckCall : NSObject

@property(nonatomic,copy) AckCallHandler handler;

-(instancetype) initWithMethod:(NSString *)method socket:(EchoSocket *)socket;

-(id) sendAckRequestBody:(NSDictionary *)body;

@end

//同步操作
@interface AckCallable : NSObject

@end

NS_ASSUME_NONNULL_END
