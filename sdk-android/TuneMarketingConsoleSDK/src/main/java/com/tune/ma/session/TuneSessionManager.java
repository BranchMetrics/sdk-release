package com.tune.ma.session;

import android.app.Activity;
import android.content.Context;

import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneActivityConnected;
import com.tune.ma.eventbus.event.TuneActivityDisconnected;
import com.tune.ma.eventbus.event.TuneAppBackgrounded;
import com.tune.ma.eventbus.event.TuneAppForegrounded;

import org.greenrobot.eventbus.Subscribe;

import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;
import java.util.UUID;

/**
 * Created by kristine on 1/4/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneSessionManager {
    // Max time to allow between Activities to transition before we consider it a new session
    public static final int SESSION_TIMEOUT = 1000;

    private Timer sessionEndTimer;
    private TuneSession session;
    private ArrayList<Activity> connectedActivities = new ArrayList<>();

    private boolean hasActivityVisible;

    private static TuneSessionManager instance = null;

    public static void clearInstance() {
        if (instance != null) {
            clearTimer();
            clearActivities();
        }
        instance = null;
    }

    static void clearTimer() {
        if (instance.sessionEndTimer != null) {
            instance.sessionEndTimer.cancel();
            instance.sessionEndTimer = null;
        }
    }

    static void clearActivities() {
        instance.connectedActivities.clear();
    }

    // TODO: delete this constructor when UserProfileManager handles writing to SharedPreferences
    public static TuneSessionManager init(Context context) {

        if (instance == null) {
            instance = new TuneSessionManager();
        }
        return instance;
    }

    public static void destroy() {
        clearInstance();
    }

    @Subscribe(priority = TuneEventBus.PRIORITY_SECOND)
    public void onEvent(TuneActivityConnected event) {
        connectActivity(event.getActivity());
    }

    @Subscribe(priority = TuneEventBus.PRIORITY_SECOND)
    public void onEvent(TuneActivityDisconnected event) {
        disconnectActivity(event.getActivity());
    }

    private synchronized void startSession() {
        // If timer is not null, it's still running
        if (sessionEndTimer != null) {
            // Cancel the app background event from being sent,
            // it hasn't been enough time between previous session end and this start
            sessionEndTimer.cancel();
            sessionEndTimer = null;
            return;
        }

        // Timer is null, so this is the first session,
        // or timer is no longer running, so it's safe to consider this a new session
        session = new TuneSession();

        long currentTime = System.currentTimeMillis();
        String sessionId = "t" + (currentTime / 1000L) + "-" + UUID.randomUUID().toString();

        TuneEventBus.post(new TuneAppForegrounded(sessionId, currentTime));
    }

    private synchronized void endSession() {
        // Schedule to send an app background event after SESSION_TIMEOUT ms have passed
        sessionEndTimer = new Timer();
        sessionEndTimer.schedule(new TimerTask() {
            @Override
            public void run() {
                if (session != null) {
                    session.setSessionLength(System.currentTimeMillis() - session.getCreatedDate());
                }

                // Null out the timer so we know it's finished running
                sessionEndTimer = null;

                // This code will be executed after SESSION_TIMEOUT ms
                TuneEventBus.post(new TuneAppBackgrounded());
            }
        }, SESSION_TIMEOUT);
    }

    private synchronized void connectActivity(Activity activity) {
        connectedActivities.add(activity);
        if (connectedActivities.size() == 1) {
            hasActivityVisible = true;
            startSession();
        }
    }

    private synchronized void disconnectActivity(Activity activity) {
        connectedActivities.remove(activity);
        if (connectedActivities.size() == 0) {
            hasActivityVisible = false;
            endSession();
        }
    }

    public ArrayList<Activity> getConnectedActivities() {
        return connectedActivities;
    }

    public TuneSession getSession() {
        return session;
    }

    public synchronized double getSecondsSinceSessionStart() {
        if (session == null) {
            return -1;
        }
        // Convert session time to seconds with decimal
        return (System.currentTimeMillis() - session.getCreatedDate()) / 1000.0;
    }

    public synchronized boolean hasActivityVisible() {
        return hasActivityVisible;
    }

    public synchronized void setActivityVisible(boolean hasActivityVisible) {
        this.hasActivityVisible = hasActivityVisible;
    }
}
