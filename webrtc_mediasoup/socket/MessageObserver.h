//
//  MessageObserver.h
//  webrtc_mediasoup
//
//  Created by JH on 2020/4/25.
//  Copyright © 2020 JH. All rights reserved.
//  消息观察者

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^AckCallHandler)(id data);

@protocol MessageObserver <NSObject>

-(void)onMethod:(NSString *)method requestId:(int) requestId notification:(BOOL)notification data:(NSDictionary *)data;

@end

NS_ASSUME_NONNULL_END
