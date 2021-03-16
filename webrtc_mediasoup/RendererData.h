//
//  RendererData.h
//  webrtc_mediasoup
//
//  Created by JH on 2020/5/2.
//  Copyright © 2020 JH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RTCEAGLVideoView;
NS_ASSUME_NONNULL_BEGIN

@interface RendererData : NSObject

@property(nonatomic,strong) NSString *videoId;

@property (nonatomic, strong) RTCEAGLVideoView *videoView;

@end

NS_ASSUME_NONNULL_END
