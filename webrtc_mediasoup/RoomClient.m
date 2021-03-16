//
//  RoomClient.m
//  webrtc_mediasoup
//
//  Created by JH on 2020/5/2.
//  Copyright © 2020 JH. All rights reserved.
//

#import "RoomClient.h"
#import <mediasoup_client_ios/Producer.h>
#import <mediasoup_client_ios/Consumer.h>
#import <mediasoup_client_ios/Device.h>
#import <mediasoup_client_ios/RTCUtils.h>
#import "MediaCapture.h"
#import "Requset.h"
#import "Utils.h"
#import "NSString+Utils.h"

@interface SendTransportHandler : NSObject<SendTransportListener>

@property(nonatomic,strong) RoomClient *parent;

- (instancetype)initWithParent:(RoomClient *)parent;

@end

@implementation SendTransportHandler

- (instancetype)initWithParent:(RoomClient *)parent
{
    self = [super init];
    if (self) {
        _parent = parent;
    }
    return self;
}

//连接mediasoup
- (void)onConnect:(Transport *)transport dtlsParameters:(NSString *)dtlsParameters {
    [self.parent handleLocalTransportConnectEvent:transport dtlsParameters:dtlsParameters];
}

- (void)onConnectionStateChange:(Transport *)transport connectionState:(NSString *)connectionState {
    
}

//Emitted when the transport needs to transmit information about a new producer to the associated server side transport.
// 请求produce的信令
- (void)onProduce:(Transport *)transport kind:(NSString *)kind rtpParameters:(NSString *)rtpParameters appData:(NSString *)appData callback:(void (^)(NSString *))callback {
    
    //生产者的id
    NSString *idString = [self.parent handleLocalTransportProduceEvent:transport kind:kind rtpParameters:rtpParameters appData:appData];
    callback(idString);
}

@end

@interface RecvTransportHandler : NSObject<RecvTransportListener>
@property(nonatomic,strong) RoomClient *parent;
@end

@implementation RecvTransportHandler

- (instancetype)initWithParent:(RoomClient *)parent{
    self = [super init];
    if (self) {
        _parent = parent;
    }
    return self;
}

//
- (void)onConnect:(Transport *)transport dtlsParameters:(NSString *)dtlsParameters {
    [self.parent handleLocalTransportConnectEvent:transport dtlsParameters:dtlsParameters];
}

- (void)onConnectionStateChange:(Transport *)transport connectionState:(NSString *)connectionState {
    
}

@end

@interface ProducerHandler : NSObject<ProducerListener>

@end

@implementation ProducerHandler



- (void)onTransportClose:(Producer *)producer {
    NSLog(@"Producer::onTransportClose");
}

@end

@interface ConsumerHandler : NSObject<ConsumerListener>

@end

@implementation ConsumerHandler



- (void)onTransportClose:(Consumer *)consumer {
     NSLog(@"consumer::onTransportClose");
}

@end

@interface RoomClient ()

@property(nonatomic,strong) EchoSocket *socket;


@property(nonatomic,strong) MediaCapture *mediaCapture;

@property(nonatomic,strong) NSMutableDictionary<NSString *,Producer *> *producers;

@property(nonatomic,strong) NSMutableDictionary<NSString *,Consumer *> *consumers;

@property(nonatomic,strong) NSMutableArray *consumersInfo;

@property(nonatomic,strong) Device *device;

@property(nonatomic,assign) BOOL joind; //是否已经加入房间

@property(nonatomic,strong) SendTransport *sendTransport;

@property(nonatomic,strong) RecvTransport *recvTransport;

@property(nonatomic,strong) NSString *displayName;


@property(nonatomic,strong) SendTransportHandler *sendTransportHandler;

@property(nonatomic,strong) RecvTransportHandler *recvTransportHandler;

@property(nonatomic,strong) ProducerHandler *producerHandler;

@property(nonatomic,strong) ConsumerHandler *consumerHandler;

@end

@implementation RoomClient

-(instancetype)initWithSocket:(EchoSocket *)socket device:(Device *)device displayName:(NSString *)displayName{
    self = [super init];
    
    if (self) {
        _socket = socket;
        _device = device;
        _mediaCapture = [[MediaCapture alloc] init];
        
        _producers = [NSMutableDictionary dictionary];
        _consumers = [NSMutableDictionary dictionary];
        _consumersInfo = [NSMutableArray array];
        _joind =NO;
        _displayName = displayName;
    }
    
    return self;
}

-(void)join{
    //设备加载不成功
    if (!self.device.isLoaded) {
        return;
    }
    
    if(self.joind){
        return;
    }
    
    id response = [Requset sendLoginRoomRequest:_socket displayName:_displayName device:[Utils deviceInfo] deviceRtpCapabilities:[NSString dictionaryWithJsonString:self.device.getRtpCapabilities] ];
    self.joind = YES;
    
    NSLog(@"join success %@",response);
}

//创建发送的Transport
-(void)createSendTransport{
    
    if (self.sendTransport != nil) {
        return;
    }
    [self createWebRtcTransport:@"send"];
}

//创建接收的Transport
-(void)createRecvTransport{
    if (self.recvTransport != nil) {
        return;
    }
    [self createWebRtcTransport:@"recv"];
}

-(void)createWebRtcTransport:(NSString *)direction{
    id response = [Requset sendCreateWebRtcTransportRequest:_socket direction:direction];
    NSLog(@"createWebRtcTransport= %@",response);
    NSString *idString =[response objectForKey:@"id"];
    NSString *iceParameters = [NSString objcToJson:[response objectForKey:@"iceParameters"]];
    NSString *iceCandidateArray =[NSString objcToJson:[response objectForKey:@"iceCandidates"]];
    NSString *dtlsParameters = [NSString objcToJson:[response objectForKey:@"dtlsParameters"]];
    
    if ([direction isEqualToString:@"send"]) {
        self.sendTransportHandler = [[SendTransportHandler alloc] initWithParent:self];
        
        //创建sendTransport
        self.sendTransport = [self.device createSendTransport:self.sendTransportHandler id:idString iceParameters:iceParameters iceCandidates:iceCandidateArray dtlsParameters:dtlsParameters];
    }else if([direction isEqualToString:@"recv"]){
        self.recvTransportHandler = [[RecvTransportHandler alloc] initWithParent:self];
        self.recvTransport = [self.device createRecvTransport:self.recvTransportHandler id:idString iceParameters:iceParameters iceCandidates:iceCandidateArray dtlsParameters:dtlsParameters];
    }
}

//创建音频或者视频生产者并发送到mediasoup
- (void)createProducer:(RTCMediaStreamTrack *)track
codecOptions:(NSString *)codecOptions
             encodings:(NSArray<RTCRtpEncodingParameters *> *)encodings{
    self.producerHandler = [[ProducerHandler alloc] init];
    
    //发送数据到mediasoup 会调用 handler->send >>> pc->setlocaldescription
    //触发onproduce
    Producer *kindProducer = [self.sendTransport produce:self.producerHandler track:track encodings:encodings codecOptions:codecOptions];
    [self.producers setObject:kindProducer forKey:kindProducer.getId];
}

//生成本地视频
-(RTCVideoTrack *) produceVideo:(RTCEAGLVideoView *)videoView{
    if (self.sendTransport ==NULL) {
        NSLog(@"transport nil");
        return NULL;
    }
    
    if (![self.device canProduce:@"video"]) {
        NSLog(@"cannot produce");
        return NULL;
    }
    
    RTCVideoTrack *videoTrack = [self.mediaCapture createVideoTrack:videoView];
      NSDictionary *codecOptions = @{ @"videoGoogleStartBitrate" : @1000 };
    NSMutableArray *encodings = [NSMutableArray array];
    [encodings addObject:[RTCUtils genRtpEncodingParameters:YES maxBitrateBps:500000 minBitrateBps:0 maxFramerate:60 numTemporalLayers:0 scaleResolutionDownBy:0]];
    [encodings addObject:[RTCUtils genRtpEncodingParameters:YES maxBitrateBps:1000000 minBitrateBps:0 maxFramerate:60 numTemporalLayers:0 scaleResolutionDownBy:0]];
    [encodings addObject:[RTCUtils genRtpEncodingParameters:YES maxBitrateBps:1500000 minBitrateBps:0 maxFramerate:60 numTemporalLayers:0 scaleResolutionDownBy:0]];
    [self createProducer:videoTrack codecOptions:[NSString objcToJson:codecOptions] encodings:encodings];
    
    return  videoTrack;
}


-(void)produceAudio{
    RTCAudioTrack *audioTrack = [self.mediaCapture createAudioTrack];
    [self createProducer:audioTrack codecOptions:nil encodings:nil];
}

//接收远端的消费者视频,获取远端的消费者
-(void) consumeTrack:(NSDictionary *)consumerInfo{
   
    if (self.recvTransport == nil) {
        //加入本地的视频
        [self.consumersInfo addObject:consumerInfo];
        return;
    }
    
    NSString *kind = [consumerInfo objectForKey:@"kind"];
    
    NSString *idString = [consumerInfo objectForKey:@"id"];
    NSString *producerId = [consumerInfo objectForKey:@"producerId"];
    NSDictionary *rtpParameters = [consumerInfo objectForKey:@"rtpParameters"];
    
    self.consumerHandler = [[ConsumerHandler alloc] init];
    Consumer *kindConsumer = [self.recvTransport consume:self.consumerHandler id:idString producerId:producerId kind:kind rtpParameters:[NSString objcToJson:rtpParameters]];
    [self.consumers setObject:kindConsumer forKey:[kindConsumer getId]];
    [self.delegate onNewConsumer:kindConsumer];
}

//处理连接的Transport
-(void) handleLocalTransportConnectEvent:(Transport *)transport dtlsParameters:(NSString *)dtlsParameters{
    [Requset sendConnectWebRTCTransportRequest:_socket transportId:[transport getId] dtlsParameters:[NSString dictionaryWithJsonString:dtlsParameters ]];
}

//处理Produce的Tranposrt
-(NSString *)handleLocalTransportProduceEvent:(Transport *)transport kind:(NSString *)kind rtpParameters:(NSString *)rtpParameters appData:(NSString *)appData{
    id data = [Requset sendProduceWebRTCTransportRequest:_socket transportId:transport.getId kind:kind rtpParameters:[NSString dictionaryWithJsonString:rtpParameters]];
//    NSLog(@"handleLocalTransportProduceEvent = %@",data);
    return [data objectForKey:@"id"];
}

//发送consumer的Id到后台
-(void)resumeRemoteVideo:(NSString *)consumerId{
     [Requset sendResumeConsumerRequest:_socket consumerId:consumerId];
}

@end
