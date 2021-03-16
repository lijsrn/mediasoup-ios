//
//  Requset.h
//  webrtc_mediasoup
//
//  Created by JH on 2020/4/30.
//  Copyright © 2020 JH. All rights reserved.
//  信令请求

#import <Foundation/Foundation.h>
#import "EchoSocket.h"

NS_ASSUME_NONNULL_BEGIN

@interface Requset : NSObject

//获取媒体能力的信令，如编解码、码率等
+(id) sendGetRoomRtpCapabilitiesRequest:(EchoSocket *)socket;

//加入房间的信令
+(id) sendLoginRoomRequest:(EchoSocket *)socket displayName:(NSString *)displayName device:(NSDictionary *)device deviceRtpCapabilities:(NSDictionary *) deviceRtpCapabilities;

//创建webrtctransport
+(id) sendCreateWebRtcTransportRequest:(EchoSocket *)socket direction:(NSString *)direction;

//连接webrtctransport
+(void) sendConnectWebRTCTransportRequest:(EchoSocket *)socket transportId:(NSString*)transportId dtlsParameters:(NSDictionary *) dtlsParameters;

//发送生产者rtpParameters
+(id)sendProduceWebRTCTransportRequest:(EchoSocket *)socket transportId:(NSString *)transportId kind:(NSString *)kind rtpParameters:(NSDictionary *)rtpParameters;

//发送恢复消费者请求
+(void)sendResumeConsumerRequest:(EchoSocket *)socket consumerId:(NSString *)consumerId;
@end

NS_ASSUME_NONNULL_END
