package com.tune.ma.eventbus.event;

/**
 * Created by johng on 2/17/16.
 */
public class TuneGetGAIDCompleted {
    private String gaid;
    private boolean limitAdTrackingEnabled;
    private String androidId;
    private boolean receivedGAID;

    public TuneGetGAIDCompleted(boolean receivedGAID, String deviceId, boolean limitAdTrackingEnabled) {
        this.receivedGAID = receivedGAID;
        if (receivedGAID) {
            this.gaid = deviceId;
            this.limitAdTrackingEnabled = limitAdTrackingEnabled;
        } else {
            this.androidId = deviceId;
        }
    }

    public String getGAID() {
        return gaid;
    }

    public boolean getLimitAdTrackingEnabled() {
        return limitAdTrackingEnabled;
    }

    public String getAndroidId() {
        return androidId;
    }

    public boolean receivedGAID() {
        return receivedGAID;
    }
}
