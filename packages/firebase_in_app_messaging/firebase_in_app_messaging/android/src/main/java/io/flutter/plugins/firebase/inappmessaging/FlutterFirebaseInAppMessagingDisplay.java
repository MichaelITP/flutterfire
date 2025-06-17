package io.flutter.plugins.firebase.inappmessaging;

import androidx.annotation.NonNull;
import com.google.firebase.inappmessaging.model.InAppMessage;
import com.google.firebase.inappmessaging.FirebaseInAppMessagingDisplay;
import com.google.firebase.inappmessaging.FirebaseInAppMessagingDisplayCallbacks;
import io.flutter.plugin.common.EventChannel;
import java.util.HashMap;
import java.util.Map;
import java.util.ArrayList;
import java.util.List;

/**
 * Forwards Firebase In-App Messaging display events to Flutter via EventChannel.
 */
public class FlutterFirebaseInAppMessagingDisplay implements FirebaseInAppMessagingDisplay {
    private EventChannel.EventSink eventSink;
    private List<InAppMessage> deferredInAppMessages = new ArrayList<InAppMessage>();

    public void setEventSink(EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
        if(eventSink != null && deferredInAppMessages.size() > 0) {
            displayMessage(deferredInAppMessages.get(0), null);
            deferredInAppMessages.remove(0);
        }
    }

    @Override
    public void displayMessage(@NonNull InAppMessage inAppMessage, FirebaseInAppMessagingDisplayCallbacks callbacks) {
        if (eventSink != null) {
            Map<String, Object> event = new HashMap<>();
            event.put("type", "displayMessage");
            event.put("message", inAppMessageToMap(inAppMessage));
            eventSink.success(event);
        } else {
            deferredInAppMessages.add(inAppMessage);
        }
    }

    // Helper to convert InAppMessage to a Map (expand as needed)
    private Map<String, Object> inAppMessageToMap(InAppMessage message) {
        Map<String, Object> map = new HashMap<>();
        map.put("campaignId", message.getCampaignId());
        map.put("title", message.getTitle() != null ? message.getTitle().getText() : null);
        map.put("body", message.getBody() != null ? message.getBody().getText() : null);
        map.put("data", message.getData());
        map.put("messageType", message.getMessageType().name());
        return map;
    }
}
