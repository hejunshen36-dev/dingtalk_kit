//
//  ApiHandler.m
//  dingtalk_kit
//
//  Created by 候建斌 on 2021/4/28.
//

#import "ApiHandler.h"
#import <DTShareKit/DTOpenAPIObject.h>
#import <DTShareKit/DTOpenKit.h>
#import <DTShareKit/DTOpenAPI.h>
@interface ApiHandler(){
    FlutterMethodChannel *_methodChannel;
}
@end

@implementation ApiHandler
- (instancetype) initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar methodChannel:(FlutterMethodChannel *)flutterMethodChannel{
    self=[super init];
    if(self){
        _methodChannel=flutterMethodChannel;
    }
    return self;
}

- (void)openAPIVersion:(FlutterMethodCall *)call result:(FlutterResult)result{
    result([@"version: " stringByAppendingString: [DTOpenAPI openAPIVersion]]);
}

- (void)registerApp:(FlutterMethodCall *)call result:(FlutterResult)result{
    NSDictionary<NSString *,id> *args=(NSDictionary<NSString *,id> *)[call arguments];
    NSString* appId=(NSString*) args[@"appId"];
    BOOL registerResult= [DTOpenAPI registerApp: appId];
    NSLog(@"[DingtalkKit]:注册API==>%@",registerResult?@"YES":@"NO");
    result(@(registerResult));
}

- (void)isDingTalkInstalled:(FlutterMethodCall *)call result:(FlutterResult)result{
    BOOL installed=[DTOpenAPI isDingTalkInstalled];
    result(@(installed));
}

- (void)isDingTalkSupportSSO:(FlutterMethodCall *)call result:(FlutterResult)result{
    BOOL res=[DTOpenAPI isDingTalkSupportSSO];
    result(@(res));
}

- (void)openDingTalk:(FlutterMethodCall *)call result:(FlutterResult)result{
    [DTOpenAPI openDingTalkOnCompletion:^(BOOL success) {
        result(@(success));
    }];
}

- (void)sendAuth:(FlutterMethodCall *)call result:(FlutterResult)result bundleId:(NSString *)bundleId{
    // send oauth request
    DTAuthorizeReq *authReq = [DTAuthorizeReq new];
    NSLog(@"%@", bundleId);
    authReq.bundleId = bundleId;
    BOOL isDingTalkSupport=[DTOpenAPI isDingTalkSupportSSO];
    if (isDingTalkSupport) {
        [DTOpenAPI sendReq:authReq completion:^(BOOL success) {
            result(@(success));
        }];
    } else {
        result([FlutterError errorWithCode:@"authError" message:@"授权失败" details:nil]);
    }
}

- (void)sendTextMessage:(FlutterMethodCall *)call result:(FlutterResult)result{
    NSDictionary<NSString *,id> *args=(NSDictionary<NSString *,id> *)[call arguments];
    NSString* text=(NSString*) args[@"text"];
    
    DTSendMessageToDingTalkReq *sendMessageReq = [[DTSendMessageToDingTalkReq alloc] init];
    
    DTMediaMessage *mediaMessage = [[DTMediaMessage alloc] init];
    
    DTMediaTextObject *textObject = [[DTMediaTextObject alloc] init];
    textObject.text = text;
    
    mediaMessage.mediaObject = textObject;
    sendMessageReq.message = mediaMessage;
    
    [DTOpenAPI sendReq:sendMessageReq completion:^(BOOL success) {
        result(@(success));
    }];
}

- (void)sendWebPageMessage:(FlutterMethodCall *)call result:(FlutterResult)result{
    NSDictionary<NSString *,id> *args=(NSDictionary<NSString *,id> *)[call arguments];
    NSString* mUrl=(NSString*) args[@"url"];
    
    DTSendMessageToDingTalkReq *sendMessageReq = [[DTSendMessageToDingTalkReq alloc] init];
    
    DTMediaMessage *mediaMessage = [[DTMediaMessage alloc] init];
    DTMediaWebObject *webObject = [[DTMediaWebObject alloc] init];
    webObject.pageURL = mUrl;
    
    mediaMessage.title = (NSString*) args[@"title"];
    
    mediaMessage.thumbURL = (NSString*) args[@"thumbUrl"];
    
    
    mediaMessage.messageDescription = (NSString*) args[@"content"];
    mediaMessage.mediaObject = webObject;
    sendMessageReq.message = mediaMessage;
    
    [DTOpenAPI sendReq:sendMessageReq completion:^(BOOL success) {
        result(@(success));
    }];
}

- (void)sendImageMessage:(FlutterMethodCall *)call result:(FlutterResult)result{
    NSDictionary<NSString *,id> *args=(NSDictionary<NSString *,id> *)[call arguments];
    NSString* imageUrl=(NSString*) args[@"picUrl"];
    
    DTSendMessageToDingTalkReq *sendMessageReq = [[DTSendMessageToDingTalkReq alloc] init];
    
    DTMediaMessage *mediaMessage = [[DTMediaMessage alloc] init];
    
    DTMediaImageObject *imageObject = [[DTMediaImageObject alloc] init];
    imageObject.imageURL = imageUrl;
    
    mediaMessage.mediaObject = imageObject;
    sendMessageReq.message = mediaMessage;
    
    [DTOpenAPI sendReq:sendMessageReq completion:^(BOOL success) {
        result(@(success));
    }];
}

@end
