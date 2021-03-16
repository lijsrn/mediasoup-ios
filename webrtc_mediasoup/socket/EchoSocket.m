//
//  EchoSocket.m
//  webrtc_mediasoup
//
//  Created by JH on 2020/4/25.
//  Copyright © 2020 JH. All rights reserved.
//

#import "EchoSocket.h"
#import "NSString+Utils.h"
#import <SRWebSocket.h>

@interface EchoSocket ()<SRWebSocketDelegate>

@property(nonatomic,strong) SRWebSocket *socket;

@property(nonatomic,strong) NSMutableDictionary *observers;

@end

@implementation EchoSocket

- (instancetype)initWithURL:(NSURL *)url registerObserver:(id<MessageObserver>) observer
{
    self = [super init];
    if (self) {
        _observers = [NSMutableDictionary dictionary];
        //与mediasoup的服务端的protoo 连接
        NSArray<NSString*> *protocols = @[@"protoo"];
        _socket = [[SRWebSocket alloc] initWithURL:url protocols:protocols];
        [self registerObserver:observer];
        //设置queue，避免线程同步时阻塞
        [_socket setDelegateDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        _socket.delegate = self;
        [_socket open];
    }
    return self;
}

//注册观察者
-(void)registerObserver:(id<MessageObserver>) observer {
    [_observers setObject:observer forKey:@([observer hash])];
}

//移除观察者
-(void)unRegisterObserver:(id<MessageObserver>) observer {
    [_observers removeObjectForKey:@([observer hash])];
}

-(void)webSocketDidOpen:(SRWebSocket *)webSocket{
     NSLog(@"socket open");
    [self.delegate webSocketDidOpen];
}

//接收信息
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSDictionary *response = [NSString dictionaryWithJsonString:message];
//    NSLog(@"%@",response);
    NSString *method = [response objectForKey:@"method"];
    NSLog(@"----%@",method);
    BOOL notification = [[response objectForKey:@"notification"] boolValue];
     NSDictionary *data = [response objectForKey:@"data"];
     int requestId = [[response objectForKey:@"id"] intValue];
     [self notifyObservers:method
                 requestId:requestId
              notification:notification
                      data:data];
}



-(void)sendMethod:(NSString *)method body:(NSDictionary *)dic requestId:(NSString *)requestId{
    //后台信令服务器接收消息的格式
    NSDictionary *d = @{
        @"request":@(YES),      //默认为YES
        @"id":@([requestId intValue]),//随机7位数
        @"method":method, //请求的名称
        @"data":dic,    //数据体
    };
    
    //后台返回的有时候没有method，通过id来对应
    
    NSString *json = [NSString objcToJson:d];
    
    //向服务端发送消息
    [_socket send:json];
}


-(void)sendMethod:(NSString *)method body:(NSDictionary *)dic{
    [self sendMethod:method body:dic requestId:[NSString randomNumWithLength:7]];
}

//
- (void)notifyObservers:(NSString *)method
   requestId:(int)requestId
notification:(BOOL)notification
                   data:(id)data{
     [_observers enumerateKeysAndObjectsUsingBlock:^(NSNumber *_Nonnull key, id<MessageObserver> _Nonnull obj, BOOL *_Nonnull stop) {
         [obj onMethod:method requestId:requestId notification:notification data:data];
     }];
}

-(void)sendWithAckMethod:(NSString *)method body:(NSDictionary *)dic completionHandler:(AckCallHandler)completionHandler{
    dispatch_queue_t queue = dispatch_queue_create("demo", NULL);
    dispatch_async(queue, ^{
        AckCall *ackCall = [[AckCall alloc] initWithMethod:method socket:self];
            id response = [ackCall sendAckRequestBody:dic];
            completionHandler(response);
    });
}


@end


@interface AckCallable ()<MessageObserver>

@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) EchoSocket *socket;
@property (nonatomic, copy) AckCallHandler callback;
@property (nonatomic, strong) NSString *requestId;

@end

@implementation AckCallable

- (instancetype)initWithMethod:(NSString *)method
                     requestId:(NSString *)requestId
                        socket:(EchoSocket *)socket {
    self = [super init];
    if (self) {
        _method = method;
        _socket = socket;
        _requestId = requestId;
    }
    return self;
}

//监听消息
-(void)listen:(AckCallHandler) callback{
    _callback = callback;
    
    NSLog(@"method %@", _method);
     [self.socket registerObserver:self];
}

-(void)onMethod:(NSString *)method requestId:(int)requestId notification:(BOOL)notification data:(NSDictionary *)data{
    if (self.requestId.intValue == requestId) {
        self.callback(data);
        [self.socket unRegisterObserver:self];
    }
}

@end

@interface AckCall(){
    dispatch_semaphore_t _semaphor;
}

@property(nonatomic,strong) NSString *method;
@property(nonatomic,strong) NSString *requestId;
@property(nonatomic,strong) EchoSocket *socket;

@property(nonatomic,strong) id response;

@end

@implementation AckCall

-(instancetype)initWithMethod:(NSString *)method socket:(EchoSocket *)socket{
    self = [super init];
    
    if (self) {
    _method = method;
    _socket = socket;
    _requestId = [NSString randomNumWithLength:7];
    _semaphor = dispatch_semaphore_create(0);
    }
    return self;
}

-(id)sendAckRequestBody:(NSDictionary *)body{
    //发送数据
    [self.socket sendMethod:_method body:body requestId:_requestId];
    
    AckCallable *callable = [[AckCallable alloc] initWithMethod:_method requestId:_requestId socket:_socket];
    
    //监听发送数据的回调
    [callable listen:^(id  _Nonnull data) {
        self.response = data;
        dispatch_semaphore_signal(self->_semaphor);
    }];
    
    //等待15s
        dispatch_semaphore_wait(_semaphor, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC)));
    return  _response;
}

@end
