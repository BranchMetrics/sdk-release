package com.tune.ma.analytics;

import android.content.Context;

import com.tune.TuneEvent;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsListener;
import com.tune.ma.analytics.model.TuneAnalyticsManagerState;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.event.TuneAnalyticsEventBase;
import com.tune.ma.analytics.model.event.TuneCustomEvent;
import com.tune.ma.analytics.model.event.TuneScreenViewEvent;
import com.tune.ma.analytics.model.event.push.TunePushActionEvent;
import com.tune.ma.analytics.model.event.push.TunePushEnabledEvent;
import com.tune.ma.analytics.model.event.push.TunePushOpenedEvent;
import com.tune.ma.analytics.model.event.session.TuneBackgroundEvent;
import com.tune.ma.analytics.model.event.session.TuneForegroundEvent;
import com.tune.ma.analytics.model.event.tracer.TuneClearVariablesEvent;
import com.tune.ma.analytics.model.event.tracer.TuneTracerEvent;
import com.tune.ma.eventbus.event.TuneActivityResumed;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;
import com.tune.ma.eventbus.event.TuneEventOccurred;
import com.tune.ma.eventbus.event.TuneSessionVariableToSet;
import com.tune.ma.eventbus.event.push.TunePushEnabled;
import com.tune.ma.eventbus.event.push.TunePushOpened;
import com.tune.ma.eventbus.event.userprofile.TuneCustomProfileVariablesCleared;
import com.tune.ma.push.model.TunePushMessage;
import com.tune.ma.utils.TuneDebugLog;
import com.tune.ma.utils.TuneJsonUtils;
import com.tune.ma.utils.TuneStringUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * Created by johng on 12/28/15.
 */
public class TuneAnalyticsManager {
    private static final String ANALYTICS_EVENTS_KEY = "events";
    private static final String CONNECTED_EVENTS_KEY = "event";

    private ScheduledThreadPoolExecutor scheduler;
    private TuneAnalyticsListener listener;
    private TuneAnalyticsManagerState state;
    private Set<TuneAnalyticsVariable> sessionVariables;

    private Boolean shouldQueueCustomEvents;
    private List<TuneEvent> customEventQueue;

    protected Context context;

    public TuneAnalyticsManager(Context context) {
        this.context = context;
        this.state = TuneAnalyticsManagerState.NOT_TRACKING;
        this.sessionVariables = new HashSet<TuneAnalyticsVariable>();

        this.shouldQueueCustomEvents = true;
        this.customEventQueue = new LinkedList<TuneEvent>();
    }

    public synchronized void onEvent(TuneEventOccurred event) {
        TuneEvent tuneEvent = event.getEvent();
        // Create TuneCustomEvent from TuneEvent
        if (shouldQueueCustomEvents()) {
            queueCustomEvent(tuneEvent);
        } else {
            TuneCustomEvent customEvent = new TuneCustomEvent(tuneEvent);
            storeAndTrackAnalyticsEvent(false, customEvent);
        }
    }

    private synchronized void queueCustomEvent(TuneEvent event) {
        customEventQueue.add(event);
    }

    private synchronized boolean shouldQueueCustomEvents() {
        return shouldQueueCustomEvents;
    }

    synchronized void setShouldQueueCustomEvents(Boolean newValue) {
        shouldQueueCustomEvents = newValue;

        if (!shouldQueueCustomEvents) {
            for (TuneEvent event: customEventQueue) {
                TuneCustomEvent customEvent = new TuneCustomEvent(event);
                storeAndTrackAnalyticsEvent(false, customEvent);
            }
            customEventQueue.clear();
        }
    }

    public void onEvent(TuneActivityResumed event) {
        // If enabled, track screen views
        if (TuneManager.getInstance().getConfigurationManager().shouldSendScreenViews()) {
            // Create and store Screen View event
            String activityName = event.getActivityName();
            TuneScreenViewEvent screenViewEvent = new TuneScreenViewEvent(activityName);
            storeAndTrackAnalyticsEvent(false, screenViewEvent);
        }
    }

    public void onEvent(TuneAppForegrounded event) {
        setShouldQueueCustomEvents(false);
        // Create and store Foregrounded event
        TuneForegroundEvent foregroundEvent = new TuneForegroundEvent();
        storeAndTrackAnalyticsEvent(false, foregroundEvent);

        startScheduledDispatch();
    }

    public void onEvent(TuneAppBackgrounded event) {
        setShouldQueueCustomEvents(true);
        // Create and store Backgrounded event
        TuneBackgroundEvent backgroundEvent = new TuneBackgroundEvent();
        storeAndTrackAnalyticsEvent(false, backgroundEvent);

        stopScheduledDispatch();
        sessionVariables.clear();
    }

    public void onEvent(TuneCustomProfileVariablesCleared event) {
        TuneClearVariablesEvent tracerEvent = new TuneClearVariablesEvent(event);

        if (scheduler != null && !scheduler.isShutdown()) {
            // Only one thread can execute at a time, so this will be queued up
            scheduler.execute(new DispatchTask().withCustomTracer(tracerEvent));
        } else {
            // If we can't send it now, save it to try and send it later
            TuneManager.getInstance().getFileManager().writeAnalytics(tracerEvent);
        }
    }

    public void onEvent(TunePushOpened event) {
        TunePushMessage message = event.getMessage();

        storeAndTrackAnalyticsEvent(false, new TunePushOpenedEvent(message));
        storeAndTrackAnalyticsEvent(false, new TunePushActionEvent(message));
    }

    public void onEvent(TunePushEnabled event) {
        boolean status = event.isEnabled();
        storeAndTrackAnalyticsEvent(false, new TunePushEnabledEvent(status));
    }

    public void onEvent(TuneSessionVariableToSet event) {
        String variableName = event.getVariableName();
        String variableValue = event.getVariableValue();

        if (event.saveToAnalyticsManager()) {
            registerSessionVariable(variableName, variableValue);
        }
    }

    public synchronized void registerSessionVariable(String variableName, String variableValue) {
        TuneAnalyticsVariable newVariable = new TuneAnalyticsVariable(variableName, variableValue);
        sessionVariables.add(newVariable);
    }

    public synchronized void addSessionVariablesToEvent(TuneAnalyticsEventBase event) {
        Set<TuneAnalyticsVariable> finalTags = new HashSet<TuneAnalyticsVariable>(sessionVariables);
        finalTags.addAll(event.getTags());
        event.setTags(finalTags);
    }

    public boolean currentlyTrackingEvents() {
        return true;
//        return (service.getConfiguration().isAnalyticsAlwaysOn() || service.getPlaylistManagerForUser().hasActiveTest()) && !this.isPaused;
    }

    public TuneAnalyticsManagerState getState() {
        return state;
    }
    public void setState(TuneAnalyticsManagerState state) {
        TuneDebugLog.d("TuneAnalyticsManager state set to " + state.toString());
        this.state = state;
    }

    // TODO: We should extend TuneAnalyticsListener to be more generic and useful for all TMA client debugging
    // TODO: similar to how TuneListener is currently used
    public TuneAnalyticsListener getListener() {
        return listener;
    }
    public void setListener(TuneAnalyticsListener listener) {
        this.listener = listener;
    }

    public void storeAndTrackAnalyticsEvent(boolean force, TuneAnalyticsEventBase event) {
//        // TODO: check if TMA is enabled
//        if (getState() == TuneAnalyticsManagerState.NOT_TRACKING) {
//            TuneDebugLog.d(TMAConstants.ARTISAN_ANALYTICS_TAG, String.format("Event not logged in db, due to ARAnalyticsManager state  %s", getState().toString()));
//            return false;
//        }
//
//        if (!currentlyTrackingEvents() && !force) {
//            TuneDebugLog.d(TMAConstants.ARTISAN_ANALYTICS_TAG, "No variants are currently running, so events are not being stored");
//            return false;
//        }

        // If connected mode is enabled, don't write to file,
        // Instead send to connected endpoint immediately
        addSessionVariablesToEvent(event);

        if (TuneManager.getInstance().getConnectedModeManager().isInConnectedMode()) {
            if (scheduler == null) {
                scheduler = new ScheduledThreadPoolExecutor(1);
            }
            if (!scheduler.isShutdown()) {
                scheduler.execute(new DispatchToConnectedModeTask(event));
            }
            return;
        }

        // Save event to local JSON file
        TuneManager.getInstance().getFileManager().writeAnalytics(event);

        return;
    }

    public TuneTracerEvent buildTracerEvent() {
        TuneTracerEvent tracer =  new TuneTracerEvent();
        addSessionVariablesToEvent(tracer);
        return tracer;
    }

    // Periodic dispatcher to send analytics every 60s by default
    public void startScheduledDispatch() {
        // If we are off then don't bother sending any more analytics.
        if (TuneManager.getInstance() == null || TuneManager.getInstance().getConfigurationManager().isTMADisabled()) {
            return;
        }

        TuneDebugLog.i("Starting Analytics Dispatching");
        if (scheduler == null) {
            scheduler = new ScheduledThreadPoolExecutor(1);
        }
        scheduler.scheduleAtFixedRate(new DispatchTask(), 0, TuneManager.getInstance().getConfigurationManager().getAnalyticsDispatchPeriod(), TimeUnit.SECONDS);
    }

    // Stop dispatcher upon receiving app background event
    public void stopScheduledDispatch() {
        if (scheduler != null) {
            TuneDebugLog.i("Stopping dispatch, flush remaining events!");
            // Send one last dispatch upon app background
            scheduler.execute(new DispatchTask());
            scheduler.shutdown();
            scheduler = null;
        }
    }

    // used for testing
    public Set<TuneAnalyticsVariable> getSessionVariables() {
        return sessionVariables;
    }

    private class DispatchTask implements Runnable {
        TuneTracerEvent customTracer;

        public DispatchTask withCustomTracer(TuneTracerEvent customTracer) {
            this.customTracer = customTracer;
            return this;
        }

        @Override
        public void run() {
            // If in connected mode or if we are disabled, don't dispatch regular analytics
            if (TuneManager.getInstance().getConnectedModeManager().isInConnectedMode() ||
                    TuneManager.getInstance().getConfigurationManager().isTMADisabled()) {
                return;
            }

            // Read analytics events from disk
            JSONArray events = TuneManager.getInstance().getFileManager().readAnalytics();

            // Add a tracer to the analytics events
            if (customTracer == null) {
                events.put(buildTracerEvent().toJson());
            } else {
                events.put(customTracer.toJson());
            }

            if (listener != null) {
                listener.dispatchingRequest(events);
            }

            try {
                // Put analytics event array under "events" key in JSONObject
                JSONObject eventsJson = new JSONObject().put(ANALYTICS_EVENTS_KEY, events);

                if (TuneManager.getInstance().getConfigurationManager().echoAnalytics()) {
                    for (int i = 0; i < events.length(); i += 1) {
                        try {
                            TuneDebugLog.alwaysLog(TuneStringUtils.format("Dispatching analytics event (%s/%s):\n%s", i + 1, events.length(), TuneJsonUtils.ppAnalyticsEvent(events.getJSONObject(i), 0)));
                        } catch (Exception ex) {
                            TuneDebugLog.alwaysLog("Failed to build event for echo:" + ex);
                        }

                    }
                }

                // Dispatch analytics events
                boolean success = TuneManager.getInstance().getApi().postAnalytics(eventsJson, listener);

                if (success) {
                    // Remove 1 from analytics events array length to account for tracer
                    TuneManager.getInstance().getFileManager().deleteAnalytics(events.length() - 1);
                } else {
                    TuneDebugLog.e("Failed to send Analytics, will try again on next interval.");
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }

    private class DispatchToConnectedModeTask implements Runnable {
        private TuneAnalyticsEventBase event;

        public DispatchToConnectedModeTask(TuneAnalyticsEventBase event) {
            this.event = event;
        }

        @Override
        public void run() {
            // Send connected event to discovery endpoint
            try {
                // Put analytics event under "event" key in JSONObject
                JSONObject eventsJson = new JSONObject().put(CONNECTED_EVENTS_KEY, event.toJson());

                if (TuneManager.getInstance().getConfigurationManager().echoAnalytics()) {
                    try {
                        TuneDebugLog.alwaysLog("Dispatching connected analytics event:\n" + TuneJsonUtils.ppAnalyticsEvent(event.toJson(), 0));
                    } catch (Exception ex) {
                        TuneDebugLog.alwaysLog("Failed to build event for echo:" + ex);
                    }
                }

                // Dispatch connected analytics event
                boolean success = TuneManager.getInstance().getApi().postConnectedAnalytics(eventsJson, listener);

                if (!success) {
                    TuneDebugLog.e("Failed to send connected Analytics");
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }

        }
    }

}
