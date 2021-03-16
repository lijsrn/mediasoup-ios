//
//  Requset.m
//  webrtc_mediasoup
//
//  Created by JH on 2020/4/30.
//  Copyright © 2020 JH. All rights reserved.
//

#import "Requset.h"

@implementation Requset

//获取rtp能力，同步请求
+(id) sendGetRoomRtpCapabilitiesRequest:(EchoSocket *)socket{
    
   return [self sendSocketAckRequest:socket method:@"getRouterRtpCapabilities" body:@{}];
}

//加入房间的信令，同步请求
+(id) sendLoginRoomRequest:(EchoSocket *)socket displayName:(NSString *)displayName device:(NSDictionary *)device deviceRtpCapabilities:(NSDictionary *) deviceRtpCapabilities{
    
    return [Requset sendSocketAckRequest:socket method:@"join" body:@{
        @"displayName":displayName,
        @"device":device,
        @"rtpCapabilities":deviceRtpCapabilities
    }];
}

//创建webrtctransport
+(id) sendCreateWebRtcTransportRequest:(EchoSocket *)socket direction:(NSString *)direction{
    return [Requset sendSocketAckRequest:socket method:@"createWebRtcTransport" body:@{
        @"forceTcp":@(NO),
        @"producing":[direction isEqualToString:@"send"] ? @(YES) :@(NO),
        @"consuming":[direction isEqualToString:@"send"] ? @(NO) :@(YES)
    }];
}

//连接webrtctransport
+(void) sendConnectWebRTCTransportRequest:(EchoSocket *)socket transportId:(NSString*)transportId dtlsParameters:(NSDictionary *) dtlsParameters{
    [socket sendMethod:@"connectWebRtcTransport" body:@{
        @"transportId":transportId,
        @"dtlsParameters":dtlsParameters
    }];
}

//发送生产者到WebRTCTransport，同步
+(id)sendProduceWebRTCTransportRequest:(EchoSocket *)socket transportId:(NSString *)transportId kind:(NSString *)kind rtpParameters:(NSDictionary *)rtpParameters{
    return [Requset sendSocketAckRequest:socket method:@"produce" body:@{
        @"transportId": transportId,
        @"kind":kind, // 音频or 视频
        @"rtpParameters":rtpParameters
    }];
}

//服务器会发送新进入房间的消费者，客户端发送消费者的id
+(void)sendResumeConsumerRequest:(EchoSocket *)socket consumerId:(NSString *)consumerId{
    [socket sendMethod:@"resumeConsumer" body:@{
        @"consumerId": consumerId
    }];
}

//同步请求方法
+(id)sendSocketAckRequest:(EchoSocket *)socket method:(NSString *)method body:(NSDictionary *)body{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block id response = NULL;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        [socket sendWithAckMethod:method body:body completionHandler:^(id  _Nonnull data) {
            response = data;
            //发送信号接触等待
            dispatch_semaphore_signal(semaphore);
        }];
    });
    
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)));
    
    return response;
}

@end
