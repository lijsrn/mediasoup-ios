//
//  MediaViewCell.m
//  webrtc_mediasoup
//
//  Created by JH on 2020/5/2.
//  Copyright © 2020 JH. All rights reserved.
//

#import "MediaViewCell.h"

@implementation MediaViewCell
- (void)addMediaView:(UIView *)view {
    [view removeFromSuperview];
    CGSize size = self.frame.size;
    view.frame = CGRectMake(0, 0, size.width, size.height);
    [self.contentView addSubview:view];
}
@end
