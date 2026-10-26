#import "DingtalkKitPlugin.h"
#import "ApiHandler.h"
#import <DTShareKit/DTOpenAPIObject.h>
#import <DTShareKit/DTOpenKit.h>
#import <DTShareKit/DTOpenAPI.h>
typedef void (^Handler)(FlutterMethodCall*,FlutterResult);


@interface DingtalkKitPlugin ()<DTOpenAPIDelegate>{
    NSObject <FlutterPluginRegistrar> *_registrar;
    NSDictionary<NSString *,Handler> *_handlerMap;
    NSString *_bundleId;
    NSString *_appId;
    FlutterMethodChannel *_channel;
    ApiHandler *_apiHandler;
}

@end



@implementation DingtalkKitPlugin

- (instancetype) initWithFlutterPluginRegistrar:(NSObject <FlutterPluginRegistrar> *) registrar{
    self = [super init];
    if(self){
        _registrar=registrar;
        _apiHandler=[[ApiHandler alloc]initWithRegistrar:registrar methodChannel:_channel];
        //方法调用处理
        _handlerMap=@{
            @"openAPIVersion":^(FlutterMethodCall* call,FlutterResult result){
                [self->_apiHandler openAPIVersion:call result:result];
            },
            @"registerApp":^(FlutterMethodCall* call,FlutterResult result){
                //记录注册信息
                NSDictionary<NSString *,id> *args=(NSDictionary<NSString *,id> *)[call arguments];
                NSString* appId=(NSString*) args[@"appId"];
                self->_appId=appId;
                NSString* bundleId=(NSString*) args[@"bundleId"];
                self->_bundleId=bundleId;
                [self->_apiHandler registerApp:call result:result];
            },
            @"isDingTalkInstalled":^(FlutterMethodCall* call,FlutterResult result){
                [self->_apiHandler isDingTalkInstalled:call result:result];
            },
            @"isDingTalkSupportSSO":^(FlutterMethodCall* call,FlutterResult result){
                [self->_apiHandler isDingTalkSupportSSO:call result:result];
            },
            @"openDingTalk":^(FlutterMethodCall* call,FlutterResult result){
                [self->_apiHandler openDingTalk:call result:result];
            },
            @"sendAuth":^(FlutterMethodCall* call,FlutterResult result){
                [self->_apiHandler sendAuth:call result:result bundleId:self->_bundleId];
            },
            @"sendTextMessage":^(FlutterMethodCall* call,FlutterResult result){
                [self->_apiHandler sendTextMessage:call result:result];
            },
            @"sendWebPageMessage":^(FlutterMethodCall* call,FlutterResult result){
                [self->_apiHandler sendWebPageMessage:call result:result];
            },
            @"sendImageMessage":^(FlutterMethodCall* call,FlutterResult result){
                [self->_apiHandler sendImageMessage:call result:result];
            },
        };
    }
    return self;
}


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"dingtalk_kit"
                                     binaryMessenger:[registrar messenger]];
    DingtalkKitPlugin* instance = [[DingtalkKitPlugin alloc] initWithFlutterPluginRegistrar:registrar];
    [registrar addMethodCallDelegate:instance channel:channel];
    [instance setChannel:channel];
    [registrar addApplicationDelegate:instance];
}

-(void)setChannel:(FlutterMethodChannel *)channel{
    _channel=channel;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if(_handlerMap[call.method]!=nil){
        _handlerMap[call.method](call,result);
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

// 将宿主 URL 回调交给钉钉 SDK；只处理已注册 App ID 对应的 Scheme。
-(BOOL)handleOpenURL:(NSURL*)url{
    // URL回调判断是钉钉回调
    if ([url.scheme isEqualToString:_appId]) {
        if([DTOpenAPI handleOpenURL:url delegate:self]){
            NSLog(@"[DingtalkKit] handled callback URL");
        }
        return YES;
    }
    return NO;
}

// delegate实现回调处理方法 onResp:
- (void)onResp:(DTBaseResp *)resp
{
    //授权登录回调参数为DTAuthorizeResp，accessCode为授权码
    if ([resp isKindOfClass:[DTAuthorizeResp class]]) {
        DTAuthorizeResp *authResp = (DTAuthorizeResp *)resp;
        NSString *accessCode = authResp.accessCode;
        // 将授权码交给Flutter端
        NSLog(@"[DingtalkKit] authorization response received");
        NSDictionary * result=@{
            @"code":accessCode,
            @"errCode":@(authResp.errorCode),
            @"errStr":authResp.errorMessage,
            @"mTransaction":@"",
            @"state":@"",
        };
        [_channel invokeMethod:@"onAuthResponse" arguments:result];
    }else if([resp isKindOfClass:[DTSendMessageToDingTalkResp class]]){
        
        DTSendMessageToDingTalkResp *shareResp = (DTSendMessageToDingTalkResp *)resp;
        // 将分享响应交给 Flutter 的 onShareResponse 监听器。
        NSLog(@"[DingtalkKit] share response received");
        // iOS 响应没有 type 属性；2 对应 SDK 的 COMMAND_SENDMESSAGE_TO_DD。
        NSDictionary * result=@{
            @"mTransaction":@"",
            @"errCode":@(shareResp.errorCode),
            @"errStr":shareResp.errorMessage ?: @"",
            @"type":@2
        };
        [_channel invokeMethod:@"onShareResponse" arguments:result];
    }
}

#pragma ApplicatioonLifeCycle
/**
 * Called if this has been registered for `UIApplicationDelegate` callbacks.
 *
 * @return `YES` if this handles the request.
 */
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    return [self handleOpenURL:url];
}
/**
 * Called if this has been registered for `UIApplicationDelegate` callbacks.
 *
 * @return `YES` if this handles the request.
 */
- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url{
    return [self handleOpenURL:url];
}
/**
 * Called if this has been registered for `UIApplicationDelegate` callbacks.
 *
 * @return `YES` if this handles the request.
 */
- (BOOL)application:(UIApplication*)application
            openURL:(NSURL*)url
  sourceApplication:(NSString*)sourceApplication
         annotation:(id)annotation{
    return [self handleOpenURL:url];
}

@end
