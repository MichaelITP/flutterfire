// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.inappmessaging;

import androidx.annotation.NonNull;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.TaskCompletionSource;
import com.google.firebase.FirebaseApp;
import com.google.firebase.inappmessaging.FirebaseInAppMessaging;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugins.firebase.core.FlutterFirebasePlugin;
import io.flutter.plugin.common.EventChannel;
import java.util.Map;
import java.util.Objects;
import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

/** FirebaseInAppMessagingPlugin */
public class FirebaseInAppMessagingPlugin
    implements FlutterFirebasePlugin, FlutterPlugin, MethodCallHandler, Application.ActivityLifecycleCallbacks {
  private MethodChannel channel;
  private EventChannel eventChannel;
  private FlutterFirebaseInAppMessagingDisplay displayComponent;
  private boolean isListening = false;
  private Application application;
  private Activity currentActivity;

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    BinaryMessenger binaryMessenger = binding.getBinaryMessenger();
    channel = new MethodChannel(binaryMessenger, "plugins.flutter.io/firebase_in_app_messaging");
    channel.setMethodCallHandler(new FirebaseInAppMessagingPlugin());

    // Register EventChannel for in-app message display events
    eventChannel = new EventChannel(binaryMessenger, "plugins.flutter.io/firebase_in_app_messaging/events");
    displayComponent = new FlutterFirebaseInAppMessagingDisplay();
    eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object arguments, EventChannel.EventSink events) {
        isListening = true;
        displayComponent.setEventSink(events);
      }

      @Override
      public void onCancel(Object arguments) {
        isListening = false;
        displayComponent.setEventSink(null);
      }
    });

    // Register for activity lifecycle callbacks
    application = (Application) binding.getApplicationContext();
    application.registerActivityLifecycleCallbacks(this);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
      channel = null;
    }
    if (eventChannel != null) {
      eventChannel.setStreamHandler(null);
      eventChannel = null;
    }
    if (displayComponent != null) {
      displayComponent.setEventSink(null);
      displayComponent = null;
    }
    if (application != null) {
      application.unregisterActivityLifecycleCallbacks(this);
      application = null;
    }
    currentActivity = null;
  }

  // ActivityLifecycleCallbacks implementation
  @Override
  public void onActivityResumed(Activity activity) {
    currentActivity = activity;
    FirebaseInAppMessaging.getInstance().setMessageDisplayComponent(displayComponent);
  }

  @Override
  public void onActivityPaused(Activity activity) {
    if (currentActivity == activity) {
      currentActivity = null;
    }
  }

  // Unused lifecycle methods
  @Override public void onActivityCreated(Activity activity, Bundle savedInstanceState) {}
  @Override public void onActivityStarted(Activity activity) {}
  @Override public void onActivityStopped(Activity activity) {}
  @Override public void onActivitySaveInstanceState(Activity activity, Bundle outState) {}
  @Override public void onActivityDestroyed(Activity activity) {}

  @Override
  public void onMethodCall(MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "FirebaseInAppMessaging#triggerEvent":
        {
          String eventName = Objects.requireNonNull(call.argument("eventName"));
          FirebaseInAppMessaging.getInstance().triggerEvent(eventName);
          result.success(null);
          break;
        }
      case "FirebaseInAppMessaging#setMessagesSuppressed":
        {
          Boolean suppress = Objects.requireNonNull(call.argument("suppress"));
          FirebaseInAppMessaging.getInstance().setMessagesSuppressed(suppress);
          result.success(null);
          break;
        }
      case "FirebaseInAppMessaging#setAutomaticDataCollectionEnabled":
        {
          Boolean enabled = (Boolean) call.argument("enabled");
          FirebaseInAppMessaging.getInstance().setAutomaticDataCollectionEnabled(enabled);
          result.success(null);
          break;
        }
      default:
        {
          result.notImplemented();
          break;
        }
    }
  }

  @Override
  public Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp) {
    TaskCompletionSource<Map<String, Object>> taskCompletionSource = new TaskCompletionSource<>();

    cachedThreadPool.execute(
        () -> {
          try {
            taskCompletionSource.setResult(null);
          } catch (Exception e) {
            taskCompletionSource.setException(e);
          }
        });

    return taskCompletionSource.getTask();
  }

  @Override
  public Task<Void> didReinitializeFirebaseCore() {
    TaskCompletionSource<Void> taskCompletionSource = new TaskCompletionSource<>();

    cachedThreadPool.execute(
        () -> {
          try {
            taskCompletionSource.setResult(null);
          } catch (Exception e) {
            taskCompletionSource.setException(e);
          }
        });

    return taskCompletionSource.getTask();
  }
}
