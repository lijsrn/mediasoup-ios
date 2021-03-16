//
//  VieoRoomPresenter.m
//  webrtc_mediasoup
//
//  Created by JH on 2020/5/2.
//  Copyright © 2020 JH. All rights reserved.
//

#import "VieoRoomPresenter.h"
#import "EchoSocket.h"
#import "RoomClient.h"
#import "Requset.h"
#import "RendererData.h"
#import "NSString+Utils.h"
#import <mediasoup_client_ios/Mediasoupclient.h>
#import <mediasoup_client_ios/Logger.h>
#import <mediasoup_client_ios/Device.h>
#import <AVKit/AVKit.h>
#import <WebRTC/WebRTC.h>

@interface VieoRoomPresenter ()<RoomClientDelegate,EchoSocketDelegate,MessageObserver>

@property(nonatomic,strong) EchoSocket *socket;

@property(nonatomic,weak) UICollectionView *collectionView;

@property(nonatomic,strong) RoomClient *roomClient;

@end

@implementation VieoRoomPresenter

- (instancetype)initWithView:(UICollectionView *)view
{
    self = [super init];
    if (self) {
        _collectionView = view;
        _mediaDatas = [NSMutableArray array];
        RendererData *data = [[RendererData alloc] init];
        [_mediaDatas addObject:data];
    }
    return self;
}

-(void)initializeClient{
    [Mediasoupclient initializePC];
    [Logger setLogLevel:LOG_DEBUG];
    [Logger setDefaultHandler];
}

- (void)connectWebSocket {
    //替换地址，roomid
    self.socket = [[EchoSocket alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"wss://xxxxxxxx/?roomId=ogujdc7r&peerId=%@", [NSString randomStringWithLength:7]]] registerObserver:self];
    self.socket.delegate = self;
}


//连接成功回调
- (void)webSocketDidOpen {
    [self initializeClient];
    
    //同步获取getRoomRtpCapabilitiesResponse
    id getRoomRtpCapabilitiesResponse = [Requset sendGetRoomRtpCapabilitiesRequest:self.socket];
     NSLog(@"getRoomRtpCapabilitiesResponse = %@", getRoomRtpCapabilitiesResponse);
    [self joinRoom:[NSString objcToJson: getRoomRtpCapabilitiesResponse]];
}

-(void)joinRoom:(NSString *)roomRtpCapabilities{
    Device *device = [[Device alloc] init];
    
    //会调用pc->createOffer
    [device load:roomRtpCapabilities];
    //创建房间
    self.roomClient = [[RoomClient alloc] initWithSocket:self.socket device:device displayName:@"demo"];
    self.roomClient.delegate = self;
//        [self.roomClient join];
    //创建消费者的传输通道
    [self.roomClient createRecvTransport];
    
    //创建生产者的传输通道
    [self.roomClient createSendTransport];

      [self.roomClient join];
    [self displayLocalVideo];
}

- (void)displayLocalVideo {
    [self checkDevicePermissions];
}

- (void)checkDevicePermissions {

    if (![AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                 completionHandler:^(BOOL granted) {
                                     [self startVideo];
                                 }];
    } else {
        [self startVideo];
    }

    if (![AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                                 completionHandler:^(BOOL granted) {
                                     [self startAudio];
                                 }];
    } else {
        [self startAudio];
    }
}

- (void)startVideo {
    [self.roomClient produceVideo:_mediaDatas[0].videoView];
}

- (void)startAudio {
    [self.roomClient produceAudio];
}

- (void)onMethod:(nonnull NSString *)method requestId:(int)requestId notification:(BOOL)notification data:(nonnull NSDictionary *)data {
    NSLog(@"data:%@-%@",data,method);
    if ([method isEqualToString:@"newConsumer"]) {
        [self.roomClient consumeTrack:data];
    }else if([method isEqualToString:@"consumerClosed"]){
        [self consumerClosed:[data objectForKey:@"consumerId"]];
    }
}

-(void)consumerClosed:(NSString *)consumerId{
    [self.mediaDatas enumerateObjectsUsingBlock:^(RendererData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.videoId isEqualToString:consumerId]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.mediaDatas removeObject:obj];
                [self.collectionView reloadData];
            });
            *stop = YES;
        }
    }];
}

-(void)onNewConsumer:(Consumer *)consumer{
    NSLog(@"=========%@",consumer.getKind);
    if ([consumer.getKind isEqualToString:@"video"]) {
        RTCVideoTrack *videoTrack = (RTCVideoTrack *)[consumer getTrack];
        videoTrack.isEnabled = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            RendererData *data = [[RendererData alloc] init];
            data.videoId = consumer.getId;
            [videoTrack addRenderer:data.videoView];
            [self.mediaDatas addObject:data];
            [self.collectionView reloadData];
        });
        
          [self.roomClient resumeRemoteVideo:consumer.getId];
    }else if ([consumer.getKind isEqualToString:@"audio"]){
        RTCAudioTrack *audioTrack = (RTCAudioTrack *)[consumer getTrack];
         audioTrack.isEnabled = YES;
//         dispatch_async(dispatch_get_main_queue(), ^{
//             RendererData *data = [[RendererData alloc] init];
//             data.videoId = consumer.getId;
//             [videoTrack addRenderer:data.videoView];
//             [self.mediaDatas addObject:data];
//             [self.collectionView reloadData];
//                audioTrack.source.volume =1;
//             NSLog(@"========%@",@(audioTrack.source.volume) );
//         });
     
           [self.roomClient resumeRemoteVideo:consumer.getId];
    }
}
@end
