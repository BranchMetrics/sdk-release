package com.tune.ma.analytics.model;

import com.tune.TuneUrlKeys;
import com.tune.ma.profile.TuneUserProfile;

/**
 * Created by johng on 1/6/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneAnalyticsSubmitter {
    public static final String SESSION_ID = "sessionId";
    public static final String DEVICE_ID = "deviceId";
    public static final String GAID = "gaid";

    private String sessionId;
    private String deviceId;
    private String googleAdvertisingId;

    public TuneAnalyticsSubmitter(TuneUserProfile profile) {
        this.sessionId = profile.getSessionId();
        this.deviceId = profile.getDeviceId();
        this.googleAdvertisingId = profile.getProfileVariableValue(TuneUrlKeys.GOOGLE_AID);
    }

    public TuneAnalyticsSubmitter(String sessionId, String deviceId, String googleAdvertisingId) {
        this.sessionId = sessionId;
        this.deviceId = deviceId;
        this.googleAdvertisingId = googleAdvertisingId;
    }

    public String getGoogleAdvertisingId() {
        return googleAdvertisingId;
    }

    public String getSessionId() {
        return sessionId;
    }

    public String getDeviceId() {
        return deviceId;
    }
}
