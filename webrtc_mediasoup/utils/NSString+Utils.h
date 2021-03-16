//
//  NSString+Utils.h
//  webrtc_mediasoup
//
//  Created by JH on 2020/4/25.
//  Copyright © 2020 JH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Utils)

+ (NSString *)randomStringWithLength:(int)len;

+ (NSString *)randomNumWithLength:(int)len;

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

+ (NSString *)objcToJson:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
