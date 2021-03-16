//
//  MediaCapture.m
//  webrtc_mediasoup
//
//  Created by JH on 2020/5/2.
//  Copyright © 2020 JH. All rights reserved.
//

#import "MediaCapture.h"
#import <WebRTC/WebRTC.h>

static NSString *const KARDMediaStreamId = @"ARDAMS";
static NSString *const KARDAudioTrackId = @"ARDAMSa0";
static NSString *const KARDVideoTrackId = @"ARDAMSv0";

@interface MediaCapture ()<RTCVideoCapturerDelegate>

@property(nonatomic,strong) RTCPeerConnectionFactory *peerConnectionFactory;

@property(nonatomic,strong) RTCMediaStream *mediaStream;

//视频捕捉
@property(nonatomic,strong) RTCCameraVideoCapturer *videoCapture;

//视频数据
@property(nonatomic,strong) RTCVideoSource *videoSource;

@end

@implementation MediaCapture

- (instancetype)init
{
    self = [super init];
    if (self) {
        _peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
        _mediaStream = [_peerConnectionFactory mediaStreamWithStreamId:KARDMediaStreamId];
    }
    return self;
}

//创建视频轨
-(RTCVideoTrack *) createVideoTrack:(RTCEAGLVideoView *)videoView{
    //获取所有的摄像头
    NSArray<AVCaptureDevice *> *captureDevices= [RTCCameraVideoCapturer captureDevices];
    
    //前置摄像头
    AVCaptureDevicePosition position = AVCaptureDevicePositionFront;
    
    if (captureDevices.count > 0 ) {
        AVCaptureDevice *device = captureDevices.firstObject;
        for (AVCaptureDevice *obj in captureDevices) {
            if (obj.position == position) {
                device = obj;
                break;
            }
        }
        
        if (device) {
           _videoSource = [_peerConnectionFactory videoSource];
            [_videoSource adaptOutputFormatToWidth:144 height:192 fps:30];
            
            _videoCapture = [[RTCCameraVideoCapturer alloc] initWithDelegate:_videoSource];
            
            //获取支持的视频格式
            AVCaptureDeviceFormat *format = [[RTCCameraVideoCapturer supportedFormatsForDevice:device] lastObject];
            
            //获取最大帧率
            CGFloat fps = [[format videoSupportedFrameRateRanges] firstObject].maxFrameRate;
            
            [_videoCapture startCaptureWithDevice:device format:format fps:fps];
            
            RTCVideoTrack *videoTrack = [_peerConnectionFactory videoTrackWithSource:_videoSource trackId:KARDVideoTrackId];
            //媒体流与视频轨绑定
            [self.mediaStream addVideoTrack:videoTrack];
            
            videoTrack.isEnabled = YES;
            
            //将本地的视频轨添加到videoView上
            [videoTrack addRenderer:videoView];
            
            return videoTrack;
        }
        
        
    }
    return nil;
}

//创建音频轨
-(RTCAudioTrack *) createAudioTrack{
    RTCAudioTrack *audioTrack = [_peerConnectionFactory audioTrackWithTrackId:KARDAudioTrackId];
    audioTrack.isEnabled = YES;
    
    //媒体流与音频流
    [self.mediaStream addAudioTrack:audioTrack];
    
    return audioTrack;
}

//采集的时候形状发送变化
- (void)capturer:(nonnull RTCVideoCapturer *)capturer didCaptureVideoFrame:(nonnull RTCVideoFrame *)frame {
    [self.videoSource  capturer:capturer didCaptureVideoFrame:frame];
}

@end
