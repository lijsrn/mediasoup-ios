//
//  RoomClient.h
//  webrtc_mediasoup
//
//  Created by JH on 2020/5/2.
//  Copyright © 2020 JH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Consumer;
@class EchoSocket;
@class Device;
@class RTCVideoTrack;
@class RTCEAGLVideoView;
@class Transport;

NS_ASSUME_NONNULL_BEGIN

@protocol RoomClientDelegate <NSObject>

//监听新的consumer进入房间
-(void)onNewConsumer:(Consumer *)consumer;

@end

@interface RoomClient : NSObject

@property(nonatomic,weak) id<RoomClientDelegate> delegate;

-(instancetype) initWithSocket:(EchoSocket *)socket device:(Device*)device displayName:(NSString *)displayName;

//加入房间
-(void)join;

//创建发送的Transport
-(void)createSendTransport;

//创建接收的Transport
-(void)createRecvTransport;

//生成视频
-(RTCVideoTrack *) produceVideo:(RTCEAGLVideoView *)videoView;

//生产者音频
-(void)produceAudio;

//消费者轨
-(void) consumeTrack:(NSDictionary *)consumerInfo;

//处理Transport连接
-(void) handleLocalTransportConnectEvent:(Transport *)transport dtlsParameters:(NSString *)dtlsParameters;

//处理
-(NSString *)handleLocalTransportProduceEvent:(Transport *)transport kind:(NSString *)kind rtpParameters:(NSString *)rtpParameters appData:(NSString *)appData;

//接收远端的消费者视频,获取远端的消费者
-( void)resumeRemoteVideo:(NSString *)consumerId;

@end

NS_ASSUME_NONNULL_END
