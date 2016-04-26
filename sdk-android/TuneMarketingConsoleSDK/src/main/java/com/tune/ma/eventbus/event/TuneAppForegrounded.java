package com.tune.ma.eventbus.event;

/**
 * Created by kristine on 1/7/16.
 */

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
