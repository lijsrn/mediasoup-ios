//
//  RenderData.m
//  webrtc_mediasoup
//
//  Created by JH on 2020/5/2.
//  Copyright © 2020 JH. All rights reserved.
//

#import "RendererData.h"
#import <WebRTC/WebRTC.h>

@implementation RendererData
- (instancetype)init {
    self = [super init];
    if (self) {
        _videoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 0, 144, 192)];
        
    }
    return self;
}

@end
