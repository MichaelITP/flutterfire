// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FirebaseInAppMessagingPlugin.h"

@import FirebaseInAppMessaging;

#if __has_include(<firebase_core/FLTFirebasePluginRegistry.h>)
#import <firebase_core/FLTFirebasePluginRegistry.h>
#else
#import <FLTFirebasePluginRegistry.h>
#endif

NSString *const kFLTFirebaseInAppMessagingChannelName =
    @"plugins.flutter.io/firebase_in_app_messaging";

NSString *const kFLTFirebaseInAppMessagingEventChannelName =
    @"plugins.flutter.io/firebase_in_app_messaging/events";

@interface FirebaseInAppMessagingPlugin () <FIRInAppMessagingDisplay, FlutterStreamHandler>
@property(nonatomic, copy) FlutterEventSink eventSink;
@property(nonatomic, strong) NSMutableArray<FIRInAppMessagingDisplayMessage *> *deferredMessages;
@end

@implementation FirebaseInAppMessagingPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:kFLTFirebaseInAppMessagingChannelName
                                  binaryMessenger:[registrar messenger]];
  FirebaseInAppMessagingPlugin *instance = [[FirebaseInAppMessagingPlugin alloc] init];
  [[FLTFirebasePluginRegistry sharedInstance] registerFirebasePlugin:instance];
  [registrar addMethodCallDelegate:instance channel:channel];

  // Register the EventChannel for in-app message display events
  FlutterEventChannel *eventChannel =
      [FlutterEventChannel eventChannelWithName:kFLTFirebaseInAppMessagingEventChannelName
                                binaryMessenger:[registrar messenger]];
  [eventChannel setStreamHandler:instance];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _deferredMessages = [NSMutableArray array];
    if ([self isCustomDisplayComponentEnabled]) {
      [FIRInAppMessaging inAppMessaging].messageDisplayComponent = self;
    }
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"FirebaseInAppMessaging#triggerEvent" isEqualToString:call.method]) {
    NSString *eventName = call.arguments[@"eventName"];
    FIRInAppMessaging *fiam = [FIRInAppMessaging inAppMessaging];
    [fiam triggerEvent:eventName];
    result(nil);
  } else if ([@"FirebaseInAppMessaging#setMessagesSuppressed" isEqualToString:call.method]) {
    BOOL suppress = [[call.arguments objectForKey:@"suppress"] boolValue];
    FIRInAppMessaging *fiam = [FIRInAppMessaging inAppMessaging];
    fiam.messageDisplaySuppressed = suppress;
    result(nil);
  } else if ([@"FirebaseInAppMessaging#setAutomaticDataCollectionEnabled"
                 isEqualToString:call.method]) {
    BOOL enabled = [[call.arguments objectForKey:@"enabled"] boolValue];
    FIRInAppMessaging *fiam = [FIRInAppMessaging inAppMessaging];
    fiam.automaticDataCollectionEnabled = enabled;
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

#pragma mark - FlutterStreamHandler

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
  self.eventSink = events;  
  // Process any deferred messages
  if (self.deferredMessages.count > 0) {
    FIRInAppMessagingDisplayMessage *message = self.deferredMessages.firstObject;
    [self.deferredMessages removeObjectAtIndex:0];
  }
  
  return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
  self.eventSink = nil;
  return nil;
}

#pragma mark - FIRInAppMessagingDisplay

- (void)displayMessage:(FIRInAppMessagingDisplayMessage *)message
       displayDelegate:(id<FIRInAppMessagingDisplayDelegate>)displayDelegate {
  if (self.eventSink == nil) {
    [self.deferredMessages addObject:message];
    return;
  }
  
  NSString *title = nil;
  NSString *body = nil;
  NSString *imageUrl = nil;
  NSDictionary *data = @{};
  // Modal
  if ([message isKindOfClass:[FIRInAppMessagingModalDisplay class]]) {
    FIRInAppMessagingModalDisplay *modal = (FIRInAppMessagingModalDisplay *)message;
    title = modal.title;
    body = modal.bodyText;
    if(modal.imageData != nil){
      imageUrl = modal.imageData.imageURL;
    }
    data = modal.appData ?: @{};
  } else if ([message isKindOfClass:[FIRInAppMessagingBannerDisplay class]]) {
    FIRInAppMessagingBannerDisplay *banner = (FIRInAppMessagingBannerDisplay *)message;
    title = banner.title;
    body = banner.bodyText;
    if(banner.imageData != nil){
      imageUrl = banner.imageData.imageURL;
    }
    data = banner.appData ?: @{};
  } else if ([message isKindOfClass:[FIRInAppMessagingImageOnlyDisplay class]]) {
    FIRInAppMessagingImageOnlyDisplay *img = (FIRInAppMessagingImageOnlyDisplay *)message;
    if(img.imageData != nil){
      imageUrl = img.imageData.imageURL;
    }
    body = @"";
    data = img.appData ?: @{};
  } else if ([message isKindOfClass:[FIRInAppMessagingCardDisplay class]]) {
    FIRInAppMessagingCardDisplay *card = (FIRInAppMessagingCardDisplay *)message;
    title = card.title;
    body = card.body;
    data = card.appData ?: @{};
  }
  NSString *campaignId = message.campaignInfo.messageID ?: @"";
  NSMutableDictionary *event = [NSMutableDictionary dictionary];
  event[@"type"] = @"displayMessage";
  event[@"message"] = @{
    @"campaignId": campaignId,
    @"title": title ?: [NSNull null],
    @"body": body ?: [NSNull null],
    @"imageUrl": imageUrl ?: [NSNull null],
    @"data": data ?: @{},
    @"messageType": NSStringFromClass([message class])
  };
  self.eventSink(event);
}

- (BOOL)isCustomDisplayComponentEnabled {
    id value = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CUSTOM_DISPLAY_COMPONENT_ENABLED"];
    if (value && [value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }
    return NO; // Default value
}

#pragma mark - FLTFirebasePlugin

- (void)didReinitializeFirebaseCore:(void (^)(void))completion {
  if (completion != nil) completion();
}

- (NSDictionary *_Nonnull)pluginConstantsForFIRApp:(FIRApp *)firebase_app {
  return @{};
}

- (NSString *_Nonnull)firebaseLibraryName {
  return @LIBRARY_NAME;
}

- (NSString *_Nonnull)firebaseLibraryVersion {
  return @LIBRARY_VERSION;
}

- (NSString *_Nonnull)flutterChannelName {
  return kFLTFirebaseInAppMessagingChannelName;
}

@end
