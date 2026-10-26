//
//  ApiHandler.h
//  dingtalk_kit
//
//  Created by 候建斌 on 2021/4/28.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
NS_ASSUME_NONNULL_BEGIN

@interface ApiHandler : NSObject
- (instancetype)initWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar methodChannel:(FlutterMethodChannel *)flutterMethodChannel;

- (void)openAPIVersion:(FlutterMethodCall *)call result:(FlutterResult)result;

///注册App
- (void)registerApp:(FlutterMethodCall *)call result:(FlutterResult)result;

///钉钉是否安装
- (void)isDingTalkInstalled:(FlutterMethodCall *)call result:(FlutterResult)result;

///查询当前钉钉客户端是否支持 SSO
- (void)isDingTalkSupportSSO:(FlutterMethodCall *)call result:(FlutterResult)result;

///打开钉钉
- (void)openDingTalk:(FlutterMethodCall *)call result:(FlutterResult)result;

///钉钉授权
- (void)sendAuth:(FlutterMethodCall *)call result:(FlutterResult)result bundleId:(NSString *)bundleId;

///分享文本
- (void)sendTextMessage:(FlutterMethodCall *)call result:(FlutterResult)result;

///分享链接
- (void)sendWebPageMessage:(FlutterMethodCall *)call result:(FlutterResult)result;

///分享图片
- (void)sendImageMessage:(FlutterMethodCall *)call result:(FlutterResult)result;
@end

NS_ASSUME_NONNULL_END
