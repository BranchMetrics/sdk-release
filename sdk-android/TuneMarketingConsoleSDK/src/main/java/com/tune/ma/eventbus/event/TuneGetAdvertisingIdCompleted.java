package com.tune.ma.eventbus.event;

/**
 * Created by johng on 2/17/16.
 */
public class TuneGetAdvertisingIdCompleted {
    private Type type;
    private String deviceId;
    private boolean limitAdTrackingEnabled;

    public TuneGetAdvertisingIdCompleted(Type type, String deviceId, boolean limitAdTrackingEnabled) {
        this.type = type;
        this.deviceId = deviceId;
        if (type == Type.GOOGLE_AID || type == Type.FIRE_AID) {
            this.limitAdTrackingEnabled = limitAdTrackingEnabled;
        }
    }

    public String getDeviceId() {
        return deviceId;
    }

    public boolean getLimitAdTrackingEnabled() {
        return limitAdTrackingEnabled;
    }

    public Type getType() {
        return type;
    }

    public enum Type {
        GOOGLE_AID,
        FIRE_AID,
        ANDROID_ID
    }
}
