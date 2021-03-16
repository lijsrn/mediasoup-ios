//
//  Utils.m
//  webrtc_mediasoup
//
//  Created by JH on 2020/4/25.
//  Copyright © 2020 JH. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+(NSDictionary *)deviceInfo{
    
    NSString *deviceName = [UIDevice currentDevice].name;
    NSString *flag = [UIDevice currentDevice].systemName;
    NSString *version = [UIDevice currentDevice].systemVersion;
    
    return @{
        @"name":deviceName,
        @"flag":flag,
        @"version":version
    };
    
}

@end
