//
//  MediaCapture.h
//  webrtc_mediasoup
//
//  Created by JH on 2020/5/2.
//  Copyright © 2020 JH. All rights reserved.
//

//视频采集模块

#import <Foundation/Foundation.h>

@class RTCVideoTrack;
@class RTCEAGLVideoView;
@class RTCAudioTrack;

NS_ASSUME_NONNULL_BEGIN

@interface MediaCapture : NSObject

//创建视频轨
-(RTCVideoTrack *) createVideoTrack:(RTCEAGLVideoView *)videoView;

//创建音频轨
-(RTCAudioTrack *) createAudioTrack;

@end

NS_ASSUME_NONNULL_END
