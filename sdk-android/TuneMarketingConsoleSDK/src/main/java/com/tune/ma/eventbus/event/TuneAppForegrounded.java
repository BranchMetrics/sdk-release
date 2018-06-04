package com.tune.ma.eventbus.event;

/**
 * Created by kristine on 1/7/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneAppForegrounded {
    String sessionId;
    Long sessionStartTime;

    public TuneAppForegrounded(String sessionId, Long sessionStartTime) {
        this.sessionId = sessionId;
        this.sessionStartTime = sessionStartTime;
    }

    public String getSessionId() {
        return sessionId;
    }

    public Long getSessionStartTime() {
        return sessionStartTime;
    }
}
