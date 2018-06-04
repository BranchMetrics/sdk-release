package com.tune.ma.eventbus;

import com.tune.TuneDebugLog;
import com.tune.TuneUrlKeys;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.eventbus.event.TuneGetAdvertisingIdCompleted;
import com.tune.ma.eventbus.event.TuneManagerInitialized;
import com.tune.ma.eventbus.event.userprofile.TuneUpdateUserProfile;

import org.greenrobot.eventbus.EventBus;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;

@Deprecated
public class TuneEventBus {
    private static final EventBus EVENT_BUS = EventBus.builder().throwSubscriberException(com.tune.BuildConfig.DEBUG_MODE).build();

    // Higher priorities get executed first.
    public static final int PRIORITY_FIRST = 100;
    public static final int PRIORITY_SECOND = 99;
    public static final int PRIORITY_THIRD = 98;
    public static final int PRIORITY_FOURTH = 97;
    public static final int PRIORITY_FIFTH = 96;
    public static final int PRIORITY_SIXTH = 95;
    public static final int PRIORITY_IRRELEVANT = 2;

    // Use a queue in order to store events that occur before TuneManager is ready
    // After TuneManager is initialized, events will be sent real-time over the bus
    private static List<Object> eventQueue = Collections.synchronizedList(new ArrayList<>());

    // Event Bus is disabled by default until turnOnTMA is true
    private static volatile boolean enabled = false;
    private static volatile boolean managerInitialized = false;
    private static volatile boolean getAdvertisingIdCompleted = false;

    public static synchronized void post(Object event) {
        if (!enabled) {
            return;
        }

        // If event being posted is TuneManagerInitialized, set flag and return
        // Do not propagate the current TuneManagerInitialized event to bus
        if (event instanceof TuneManagerInitialized) {
            managerInitialized = true;
            // Dequeue events if TuneGetAdvertisingIdCompleted event was already received
            if (getAdvertisingIdCompleted) {
                dequeue();
            }
            return;
        }

        // If event being posted is TuneGetAdvertisingIdCompleted, set flag, set advertising ID in user profile, and dequeue events
        // Do not propagate the current TuneGetAdvertisingIdCompleted event to bus
        if (event instanceof TuneGetAdvertisingIdCompleted) {
            getAdvertisingIdCompleted = true;
            TuneGetAdvertisingIdCompleted advertisingIdEvent = (TuneGetAdvertisingIdCompleted) event;
            // Insert device id update events into the beginning of queue so they get processed first
            // Update advertising ID user profile values
            switch (advertisingIdEvent.getType()) {
                case ANDROID_ID:
                    // We received ANDROID ID as fallback, update ANDROID_ID user profile values
                    eventQueue.add(0, new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ANDROID_ID, advertisingIdEvent.getDeviceId())));
                    break;
                case FIRE_AID:
                    // We received a Fire Advertising ID, update FIRE_AID user profile values
                    eventQueue.add(0, new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.FIRE_AID, advertisingIdEvent.getDeviceId())));
                    eventQueue.add(1, new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.FIRE_AD_TRACKING_DISABLED, advertisingIdEvent.getLimitAdTrackingEnabled())));
                    break;
                case GOOGLE_AID:
                    // We received a GAID, update GAID user profile values
                    eventQueue.add(0, new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.GOOGLE_AID, advertisingIdEvent.getDeviceId())));
                    eventQueue.add(1, new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.GOOGLE_AD_TRACKING_DISABLED, advertisingIdEvent.getLimitAdTrackingEnabled())));
                    break;
                case PLATFORM_AID:
                    // We received a Platform Advertising ID, update PLATFORM_AID user profile values
                    eventQueue.add(0, new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PLATFORM_AID, advertisingIdEvent.getDeviceId())));
                    eventQueue.add(1, new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PLATFORM_AD_TRACKING_DISABLED, advertisingIdEvent.getLimitAdTrackingEnabled())));
                    break;
                default:
                    break;
            }
            
            // Dequeue events if ManagerInitialized event was already received
            if (managerInitialized) {
                dequeue();
            }
            return;
        }

        // Check the status of whether the two above events were received...
        if (managerInitialized && getAdvertisingIdCompleted) {
            // Post the event if both TuneManager was initialized and GetAdvertisingId completed
            EVENT_BUS.post(event);
        } else {
            // Queue the event otherwise
            TuneDebugLog.d("Adding event " + event.getClass().getName() + " to queue with current size " + eventQueue.size());
            eventQueue.add(event);
        }
    }

    /**
     * Register with the EventBus
     * @param subscriber Object that implements the Subscribe annotation
     */
    public static void register(Object subscriber) {
        if (!enabled) {
            return;
        }
        EVENT_BUS.register(subscriber);
    }

    public static void unregister(Object subscriber) {
        if (!enabled || subscriber == null) {
            return;
        }
        EVENT_BUS.unregister(subscriber);
    }

    public static synchronized void disable() {
        // Disable bus from being used
        enabled = false;
        // Remove any queued events without sending
        eventQueue.clear();
    }

    public static void enable() {
        enabled = true;
    }

    static synchronized List<Object> getQueue() {
        return eventQueue;
    }

    public static void clearFlags() {
        managerInitialized = false;
        getAdvertisingIdCompleted = false;
    }

    private static synchronized void dequeue() {
        // Dequeue the queued events
        Iterator<Object> it = eventQueue.iterator();
        while (it.hasNext()) {
            Object queuedEvent = it.next();
            EVENT_BUS.post(queuedEvent);
            it.remove();
        }
    }

    // This method is only used for the EnableDisable tests
    public static boolean isEnabled() {
        return enabled;
    }

    /** For unit test primarily. */
    public static void clearCaches() {
        EVENT_BUS.clearCaches();
    }
}
