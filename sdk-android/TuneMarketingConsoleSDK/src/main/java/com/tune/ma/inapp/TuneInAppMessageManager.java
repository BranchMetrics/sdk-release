package com.tune.ma.inapp;

import android.app.Activity;
import android.content.Context;
import android.text.TextUtils;

import com.tune.TuneEvent;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.event.TuneAnalyticsEventBase;
import com.tune.ma.analytics.model.event.TuneCustomEvent;
import com.tune.ma.analytics.model.event.TuneDeeplinkOpenedEvent;
import com.tune.ma.analytics.model.event.TuneScreenViewEvent;
import com.tune.ma.analytics.model.event.push.TunePushEnabledEvent;
import com.tune.ma.analytics.model.event.push.TunePushOpenedEvent;
import com.tune.ma.analytics.model.event.session.TuneFirstPlaylistDownloadedEvent;
import com.tune.ma.eventbus.event.TuneActivityResumed;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneDeeplinkOpened;
import com.tune.ma.eventbus.event.TuneEventOccurred;
import com.tune.ma.eventbus.event.TunePlaylistManagerCurrentPlaylistChanged;
import com.tune.ma.eventbus.event.TunePlaylistManagerFirstPlaylistDownloaded;
import com.tune.ma.eventbus.event.push.TunePushEnabled;
import com.tune.ma.eventbus.event.push.TunePushOpened;
import com.tune.ma.inapp.model.TuneInAppMessage;
import com.tune.ma.inapp.model.TuneMessageDisplayCount;
import com.tune.ma.inapp.model.TuneTriggerEvent;
import com.tune.ma.inapp.model.banner.TuneBanner;
import com.tune.ma.inapp.model.fullscreen.TuneFullScreen;
import com.tune.ma.inapp.model.modal.TuneModal;
import com.tune.ma.playlist.model.TunePlaylist;
import com.tune.ma.push.model.TunePushMessage;
import com.tune.ma.utils.TuneJsonUtils;
import com.tune.ma.utils.TuneSharedPrefsDelegate;
import com.tune.ma.utils.TuneStringUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static com.tune.ma.inapp.TuneInAppMessageConstants.MESSAGE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.MESSAGE_TYPE_BANNER;
import static com.tune.ma.inapp.TuneInAppMessageConstants.MESSAGE_TYPE_FULLSCREEN;
import static com.tune.ma.inapp.TuneInAppMessageConstants.MESSAGE_TYPE_KEY;
import static com.tune.ma.inapp.TuneInAppMessageConstants.MESSAGE_TYPE_MODAL;

/**
 * Created by johng on 2/21/17.
 */

public class TuneInAppMessageManager {
    public static final String PREFS_TMA_INAPP = "com.tune.ma.inapp";
    public static final String PREFS_DISPLAY_COUNT_KEY = "MESSAGE_DISPLAY_COUNT_MAP";

    private Map<String, TuneInAppMessage> inAppMessagesByIds;
    private Map<String, List<TuneInAppMessage>> inAppMessagesByEvents;
    private Map<String, TuneMessageDisplayCount> messageDisplayCountMap;
    private int customFullScreenLoadingScreenLayoutId;

    private TuneBanner previouslyShownBanner;
    private TuneModal previouslyShownModal;
    private TuneFullScreen previouslyShownFullScreen;
    private TuneInAppMessage previouslyShownTestMessage;

    private TuneSharedPrefsDelegate sharedPrefsDelegate;

    private boolean playlistDownloaded;
    private Set<TuneAnalyticsEventBase> triggerEventsSeenPriorToPlaylistDownload;
    private Map<String, String> deeplinksOpenedPriorToPlaylistDownload;

    public TuneInAppMessageManager(Context context) {
        inAppMessagesByIds = new HashMap<>();
        inAppMessagesByEvents = new HashMap<>();

        sharedPrefsDelegate = new TuneSharedPrefsDelegate(context, PREFS_TMA_INAPP);
        messageDisplayCountMap = loadOrCreateMessageCountMap();

        playlistDownloaded = false;
        triggerEventsSeenPriorToPlaylistDownload = new HashSet<>();
        deeplinksOpenedPriorToPlaylistDownload = new HashMap<>();
    }

    public synchronized Map<String, TuneInAppMessage> getMessagesByIds() {
        return new HashMap<>(inAppMessagesByIds);
    }

    public synchronized void setMessagesByIds(Map<String, TuneInAppMessage> messages) {
        inAppMessagesByIds = messages;
    }

    public synchronized Map<String, List<TuneInAppMessage>> getMessagesByTriggerEvents() {
        return new HashMap<>(inAppMessagesByEvents);
    }

    public synchronized void setMessagesByTriggerEvents(Map<String, List<TuneInAppMessage>> messages) {
        inAppMessagesByEvents = messages;
    }

    public synchronized Map<String, TuneMessageDisplayCount> getMessageCountsByCampaignIds() {
        return new HashMap<>(messageDisplayCountMap);
    }

    public synchronized void setMessageCountsByCampaignIds(Map<String, TuneMessageDisplayCount> messageCounts) {
        messageDisplayCountMap = messageCounts;
    }

    public synchronized List<TuneInAppMessage> getMessagesForCustomEvent(String eventName) {
        if (eventName == null || eventName.isEmpty()) {
            return new ArrayList<>();
        }
        TuneEvent tuneEvent = new TuneEvent(eventName);
        TuneCustomEvent customEvent = new TuneCustomEvent(tuneEvent);
        return getMessagesForTriggerEvent(customEvent);
    }

    public synchronized List<TuneInAppMessage> getMessagesForPushOpened(String pushId) {
        if (pushId == null || pushId.isEmpty()) {
            return new ArrayList<>();
        }
        TunePushMessage pushMessageFromPushId = TunePushMessage.initForTriggerEvent(pushId);
        TunePushOpenedEvent pushOpenedEvent = new TunePushOpenedEvent(pushMessageFromPushId);
        return getMessagesForTriggerEvent(pushOpenedEvent);
    }

    public synchronized List<TuneInAppMessage> getMessagesForPushEnabled(boolean enabled) {
        TunePushEnabledEvent pushEnabledEvent = new TunePushEnabledEvent(enabled);
        return getMessagesForTriggerEvent(pushEnabledEvent);
    }

    public synchronized List<TuneInAppMessage> getMessagesForStartsApp() {
        // "Starts App" event maps to FirstPlaylistDownloaded event
        return getMessagesForTriggerEvent(new TuneFirstPlaylistDownloadedEvent());
    }

    public synchronized List<TuneInAppMessage> getMessagesForScreenViewed(String activityName) {
        if (activityName == null || activityName.isEmpty()) {
            return new ArrayList<>();
        }
        TuneScreenViewEvent screenViewEvent = new TuneScreenViewEvent(activityName);
        return getMessagesForTriggerEvent(screenViewEvent);
    }

    // Preload all messages when an Activity is visible
    public synchronized void preloadMessages(final Activity activity) {
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                for (TuneInAppMessage message : inAppMessagesByIds.values()) {
                    message.load(activity);
                }
            }
        });
    }

    public synchronized void preloadMessagesForCustomEvent(final Activity activity, String eventName) {
        if (eventName == null || eventName.isEmpty()) {
            return;
        }
        TuneEvent tuneEvent = new TuneEvent(eventName);
        final TuneCustomEvent customEvent = new TuneCustomEvent(tuneEvent);
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                for (TuneInAppMessage message : getMessagesForTriggerEvent(customEvent)) {
                    message.load(activity);
                }
            }
        });
    }

    public synchronized void preloadMessageWithId(final Activity activity, String messageId) {
        if (messageId == null || messageId.isEmpty()) {
            return;
        }
        final TuneInAppMessage message = getMessagesByIds().get(messageId);
        if (message != null) {
            activity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    message.load(activity);
                }
            });
        }
    }

    // Clear all counts' "number of times shown this session" when new session starts
    public synchronized void onEvent(TuneAppForegrounded event) {
        for (Map.Entry<String, TuneMessageDisplayCount> entry : messageDisplayCountMap.entrySet()) {
            TuneMessageDisplayCount count = entry.getValue();
            count.setNumberOfTimesShownThisSession(0);
        }
        updateCountMapInSharedPreferences();
    }

    public synchronized void onEvent(TuneAppBackgrounded event) {
        // Clear any trigger events that occurred before first playlist download
        triggerEventsSeenPriorToPlaylistDownload.clear();
        deeplinksOpenedPriorToPlaylistDownload.clear();
        playlistDownloaded = false;
    }

    public synchronized void onEvent(TunePlaylistManagerCurrentPlaylistChanged event) {
        // Make a temp copy of the previous messages, for comparing frequency changes
        Map<String, TuneInAppMessage> previousMessagesByIds = new HashMap<>(inAppMessagesByIds);

        // Rebuild the maps if the playlist changes
        inAppMessagesByIds = new HashMap<>();
        inAppMessagesByEvents = new HashMap<>();

        // Populate in-app messages from playlist
        TunePlaylist activePlaylist = event.getNewPlaylist();

        JSONObject inAppMessagesJson = activePlaylist.getInAppMessages();
        if (inAppMessagesJson == null) {
            return;
        }

        // Iterate through in-app messages and create map of messages
        Iterator<String> inAppMessagesIter = inAppMessagesJson.keys();
        String triggerRuleId;
        List<String> campaignIds = new ArrayList<>();
        while (inAppMessagesIter.hasNext()) {
            triggerRuleId = inAppMessagesIter.next();

            JSONObject inAppMessageVariationJson = TuneJsonUtils.getJSONObject(inAppMessagesJson, triggerRuleId);

            // Instantiate different TuneInAppMessage subclass based on message type
            // TODO: refactor or find a cleaner way to parse messageType from inner "message" json
            JSONObject messageJson = TuneJsonUtils.getJSONObject(inAppMessageVariationJson, MESSAGE_KEY);
            if (messageJson == null) {
                return;
            }
            String messageType = TuneJsonUtils.getString(messageJson, MESSAGE_TYPE_KEY);
            if (messageType == null) {
                return;
            }

            TuneInAppMessage message = null;
            switch (messageType) {
                case MESSAGE_TYPE_BANNER:
                    message = new TuneBanner(inAppMessageVariationJson);
                    break;
                case MESSAGE_TYPE_MODAL:
                    message = new TuneModal(inAppMessageVariationJson);
                    break;
                case MESSAGE_TYPE_FULLSCREEN:
                    message = new TuneFullScreen(inAppMessageVariationJson);
                    break;
                default:
                    break;
            }

            // If we created an in-app message object, add it to the maps
            if (message != null) {
                // Add it to the ids map under its id
                inAppMessagesByIds.put(message.getId(), message);

                // Add it to the events map under its trigger events
                for (TuneTriggerEvent triggerEvent : message.getTriggerEvents()) {
                    List<TuneInAppMessage> messagesList;
                    if (inAppMessagesByEvents.containsKey(triggerEvent.getEventMd5())) {
                        // If map has the trigger event, get the existing list of messages
                        messagesList = inAppMessagesByEvents.get(triggerEvent.getEventMd5());
                    } else {
                        // Create new list if map doesn't contain the trigger event
                        messagesList = new ArrayList<>();
                    }
                    // Add the message to the list of messages that have this trigger event
                    messagesList.add(message);
                    inAppMessagesByEvents.put(triggerEvent.getEventMd5(), messagesList);
                }

                // Add to list of campaign ids seen in the playlist
                campaignIds.add(message.getCampaign().getCampaignId());
            }
        }

        // Filter the message display counts map for only the message campaign ids that were seen in the playlist
        messageDisplayCountMap.keySet().retainAll(campaignIds);

        // If message display counts map is empty, we don't need to prune it
        if (messageDisplayCountMap.isEmpty()) {
            return;
        }

        // Clear the display counts for any message if its trigger or frequency has changed

        // Keep only common message ids between the two maps
        // Remove any message ids from previous map that are no longer in new playlist
        // Since those messages are gone now, we don't need to look at them for changes
        previousMessagesByIds.keySet().retainAll(inAppMessagesByIds.keySet());

        // Go through old messages and compare the triggers to the new message's triggers
        // This saves us a little time vs going through new messages that don't have an equivalent old message
        for (TuneInAppMessage previousMessage : previousMessagesByIds.values()) {
            String previousMessageId = previousMessage.getId();
            if (inAppMessagesByIds.containsKey(previousMessageId)) {
                TuneInAppMessage newMessage = inAppMessagesByIds.get(previousMessageId);

                // If the triggers and frequencies differ, clear the display count
                if (!newMessage.getTriggerEvents().containsAll(previousMessage.getTriggerEvents())) {
                    messageDisplayCountMap.remove(newMessage.getCampaign().getCampaignId());
                }
            }
        }
    }

    /************
     * Triggers *
     ************/

    // Listen for custom TuneEvent trigger
    public synchronized void onEventMainThread(TuneEventOccurred event) {
        // No messages to trigger
        if (noMessagesToTrigger()) {
            return;
        }

        // Check if any in-app messages should be triggered from measureEvent call
        TuneEvent tuneEvent = event.getEvent();

        // Create a TuneCustomEvent from TuneEvent
        TuneCustomEvent customEvent = new TuneCustomEvent(tuneEvent);

        triggerMessagesForEvent(customEvent);
    }

    public synchronized void onEventMainThread(TuneDeeplinkOpened event) {
        String reducedUrl = TuneStringUtils.reduceUrlToPath(event.getDeeplinkUrl());
        TuneDeeplinkOpenedEvent deeplinkOpened = new TuneDeeplinkOpenedEvent(reducedUrl);
        // Store deeplink opened event locally as having occurred prior to first playlist download
        if (!playlistDownloaded) {
            triggerEventsSeenPriorToPlaylistDownload.add(deeplinkOpened);
            deeplinksOpenedPriorToPlaylistDownload.put(deeplinkOpened.getEventMd5(), event.getDeeplinkUrl());
        }

        // No messages to trigger
        if (noMessagesToTrigger()) {
            return;
        }

        // Check if any in-app messages should be triggered from deeplink open
        triggerMessagesForEvent(deeplinkOpened);
    }

    // Listen for push opened trigger
    public synchronized void onEventMainThread(TunePushOpened event) {
        TunePushMessage message = event.getMessage();
        TunePushOpenedEvent pushOpened = new TunePushOpenedEvent(message);
        // Store push opened event locally as having occurred prior to first playlist download
        if (!playlistDownloaded) {
            triggerEventsSeenPriorToPlaylistDownload.add(pushOpened);
        }

        // No messages to trigger
        if (noMessagesToTrigger()) {
            return;
        }

        // Check if any in-app messages should be triggered from push open
        triggerMessagesForEvent(pushOpened);
    }

    // Listen for push enabled trigger
    public synchronized void onEventMainThread(TunePushEnabled event) {
        // No messages to trigger
        if (noMessagesToTrigger()) {
            return;
        }

        // Check if any in-app messages should be triggered from push enabled
        boolean pushEnabled = event.isEnabled();
        TunePushEnabledEvent pushEnabledEvent = new TunePushEnabledEvent(pushEnabled);
        triggerMessagesForEvent(pushEnabledEvent);
    }

    // Listen for first playlist download to trigger deeplink or push opens
    public synchronized void onEventMainThread(TunePlaylistManagerFirstPlaylistDownloaded event) {
        playlistDownloaded = true;

        // No messages to trigger
        if (noMessagesToTrigger()) {
            return;
        }

        // Trigger messages for any deeplink opens or push opens that previously occurred in this session
        if (triggerEventsSeenPriorToPlaylistDownload.size() > 0) {
            for (TuneAnalyticsEventBase analyticsEvent : triggerEventsSeenPriorToPlaylistDownload) {
                // Check if it's already been displayed this session
                List<TuneInAppMessage> messagesForEvent = inAppMessagesByEvents.get(analyticsEvent.getEventMd5());
                if (messagesForEvent != null) {
                    for (TuneInAppMessage message : messagesForEvent) {
                        String campaignId = message.getCampaign().getCampaignId();
                        TuneMessageDisplayCount displayCount = messageDisplayCountMap.get(campaignId);

                        // Only show message if it hasn't been shown this session
                        if (displayCount == null || displayCount.getNumberOfTimesShownThisSession() == 0) {
                            triggerMessagesForEvent(analyticsEvent);
                        }
                    }
                }
            }
        }

        // Trigger "Starts App" messages on first playlist download
        TuneFirstPlaylistDownloadedEvent firstPlaylistDownloadedEvent = new TuneFirstPlaylistDownloadedEvent();
        triggerMessagesForEvent(firstPlaylistDownloadedEvent);
    }

    // Listen for app foregrounded (Starts App) trigger
    public synchronized void onEventMainThread(TuneAppForegrounded event) {
        if (noMessagesToTrigger()) {
            return;
        }

        // Show any messages that have FirstPlaylistDownloaded as a trigger event, so that they truly get shown on "Starts App"
        TuneFirstPlaylistDownloadedEvent firstPlaylistDownloadedEvent = new TuneFirstPlaylistDownloadedEvent();
        triggerMessagesForEvent(firstPlaylistDownloadedEvent);
    }

    // Listen for Activity resume (Screen View) trigger
    public synchronized void onEventMainThread(TuneActivityResumed event) {
        // No messages to trigger
        if (noMessagesToTrigger()) {
            return;
        }

        if (TuneManager.getInstance().getConfigurationManager().shouldSendScreenViews()) {
            // Check if any in-app messages should be triggered from screen view
            String activityName = event.getActivityName();
            TuneScreenViewEvent screenViewEvent = new TuneScreenViewEvent(activityName);
            triggerMessagesForEvent(screenViewEvent);
        }
    }

    public void setFullScreenLoadingScreen(int layoutId) {
        customFullScreenLoadingScreenLayoutId = layoutId;
    }

    public int getFullScreenLoadingScreen() {
        return customFullScreenLoadingScreenLayoutId;
    }

    private List<TuneInAppMessage> getMessagesForTriggerEvent(TuneAnalyticsEventBase event) {
        String eventMd5 = event.getEventMd5();
        // If the messages don't have this event as a trigger, return empty list
        if (!inAppMessagesByEvents.containsKey(eventMd5)) {
            return new ArrayList<>();
        }

        return inAppMessagesByEvents.get(eventMd5);
    }

    private boolean noMessagesToTrigger() {
        return inAppMessagesByEvents == null || inAppMessagesByEvents.isEmpty();
    }

    private void triggerMessagesForEvent(TuneAnalyticsEventBase event) {
        // Get Fiveline MD5 to compare to trigger events
        String eventMd5 = event.getEventMd5();

        // Return if there are no messages with this trigger event
        if (!inAppMessagesByEvents.containsKey(eventMd5)) {
            return;
        }

        // Iterate through messages that have this event as a trigger
        List<TuneInAppMessage> messagesForEvent = inAppMessagesByEvents.get(eventMd5);
        // Try to show each message
        for (TuneInAppMessage message : messagesForEvent) {
            // Update events seen count for the message
            markEventTriggeredForMessage(message, eventMd5);

            TuneMessageDisplayCount displayCountForMessage = getCountForMessage(message, eventMd5);
            if (message.shouldDisplay(displayCountForMessage)) {
                // If it's already showing, don't remove it or trigger a new one
                if (isMessageCurrentlyShowing(message)) {
                    continue;
                }

                // Mark message as shown to increment display counts
                markMessageShown(displayCountForMessage);

                message.display();
            }
        }
    }

    /**
     * Check if there's already a message showing.
     * If a message is showing, don't show the new message.
     * @param newMessage New in-app message to display.
     * @return whether there's a currently visible nessage.
     */
    public synchronized boolean isMessageCurrentlyShowing(TuneInAppMessage newMessage) {
        if (newMessage instanceof TuneBanner) {
            if (previouslyShownBanner != null && previouslyShownBanner.isVisible()) {
                return true;
            }
            previouslyShownBanner = (TuneBanner)newMessage;
        } else if (newMessage instanceof TuneModal) {
            if (previouslyShownModal != null && previouslyShownModal.isVisible()) {
                return true;
            }
            previouslyShownModal = (TuneModal)newMessage;
        } else if (newMessage instanceof TuneFullScreen) {
            if (previouslyShownFullScreen != null && previouslyShownFullScreen.isVisible()) {
                return true;
            }
            previouslyShownFullScreen = (TuneFullScreen)newMessage;
        } else {
            if (previouslyShownTestMessage != null && previouslyShownTestMessage.isVisible()) {
                return true;
            }
            previouslyShownTestMessage = newMessage;
        }
        return false;
    }

    public synchronized TuneMessageDisplayCount getCountForMessage(TuneInAppMessage message, String triggerEvent) {
        TuneMessageDisplayCount count = messageDisplayCountMap.get(message.getCampaign().getCampaignId());
        // If no display count was found in the map, create a new TuneMessageDisplayCount
        if (count == null) {
            count = new TuneMessageDisplayCount(message.getCampaign().getCampaignId(), triggerEvent);
            // Save this new count to the map
            messageDisplayCountMap.put(count.getCampaignId(), count);
        }
        return count;
    }

    public synchronized void markEventTriggeredForMessage(TuneInAppMessage message, String triggerEvent) {
        TuneMessageDisplayCount count = getCountForMessage(message, triggerEvent);
        count.incrementEventsSeenSinceShown();
        updateCount(count);
    }

    public synchronized void markMessageShown(TuneMessageDisplayCount displayCount) {
        displayCount.setEventsSeenSinceShown(0);
        displayCount.setLastShownDate(new Date());
        displayCount.incrementLifetimeShownCount();
        displayCount.incrementNumberOfTimesShownThisSession();
        updateCount(displayCount);
    }

    public synchronized void updateCount(TuneMessageDisplayCount count) {
        // Save the updated count to the map
        messageDisplayCountMap.put(count.getCampaignId(), count);
        updateCountMapInSharedPreferences();
    }

    public synchronized void updateCountMapInSharedPreferences() {
        // Build JSONObject from map manually :(
        JSONObject displayCountMapJson = new JSONObject();
        for (Map.Entry<String, TuneMessageDisplayCount> entry : messageDisplayCountMap.entrySet()) {
            try {
                displayCountMapJson.put(entry.getKey(), entry.getValue().toJson());
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        // Save the JSON string representation of the map to SharedPreferences
        sharedPrefsDelegate.saveToSharedPreferences(PREFS_DISPLAY_COUNT_KEY, displayCountMapJson.toString());
    }

    public synchronized Map<String, TuneMessageDisplayCount> loadOrCreateMessageCountMap() {
        Map<String, TuneMessageDisplayCount> displayCountMap = new HashMap<String, TuneMessageDisplayCount>();

        // If display count map was found in SharedPreferences, rebuild it from the stored JSON string representation
        String storedMessageFrequencyMap = sharedPrefsDelegate.getStringFromSharedPreferences(PREFS_DISPLAY_COUNT_KEY);
        if (!TextUtils.isEmpty(storedMessageFrequencyMap)) {
            try {
                // Reload existing map from stored JSON string
                JSONObject mapJson = new JSONObject(storedMessageFrequencyMap);

                // Rebuild display count map from JSON
                Iterator<String> iter = mapJson.keys();
                while (iter.hasNext()) {
                    String key = iter.next();
                    try {
                        TuneMessageDisplayCount value = TuneMessageDisplayCount.fromJson(mapJson.getJSONObject(key));
                        displayCountMap.put(key, value);
                    } catch (JSONException e) {
                    }
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        return displayCountMap;
    }

    public synchronized void clearCountMap() {
        messageDisplayCountMap.clear();
        sharedPrefsDelegate.clearSharedPreferences();
    }
}