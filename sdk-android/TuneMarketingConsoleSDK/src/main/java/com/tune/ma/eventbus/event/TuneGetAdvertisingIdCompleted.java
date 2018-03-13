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
        switch(type) {
            case PLATFORM_AID:
            case GOOGLE_AID:
            case FIRE_AID:
                this.limitAdTrackingEnabled = limitAdTrackingEnabled;
                break;

            default:
                break;
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
        PLATFORM_AID,
        @Deprecated GOOGLE_AID,
        @Deprecated FIRE_AID,
        ANDROID_ID
    }
}
