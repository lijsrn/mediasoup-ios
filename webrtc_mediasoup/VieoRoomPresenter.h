//
//  VieoRoomPresenter.h
//  webrtc_mediasoup
//
//  Created by JH on 2020/5/2.
//  Copyright © 2020 JH. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RendererData;

NS_ASSUME_NONNULL_BEGIN

@interface VieoRoomPresenter : NSObject

//渲染数据源
@property(nonatomic,strong) NSMutableArray<RendererData *> *mediaDatas;

- (instancetype)initWithView:(UICollectionView *)view;
- (void)connectWebSocket;

@end

NS_ASSUME_NONNULL_END
