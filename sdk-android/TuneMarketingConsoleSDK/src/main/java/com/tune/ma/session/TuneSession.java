package com.tune.ma.session;

import java.io.Serializable;
import java.util.UUID;

public class TuneSession implements Serializable {
    private static final long serialVersionUID = -5056561995671282268L;
    private String sessionId;
    private long createdDate;
    private long lastSessionDate = 0l;
    private int userSessionCount = 1;
    private long sessionLength = 0;

    public TuneSession() {
        this.sessionId = generateSessionID();
        this.createdDate = System.currentTimeMillis();
    }

    public String getSessionId() {
        return sessionId;
    }

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }

    public long getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(long createdDate) {
        this.createdDate = createdDate;
    }

    public long getLastSessionDate() {
        return lastSessionDate;
    }

    public void setLastSessionDate(long lastSessionDate) {
        this.lastSessionDate = lastSessionDate;
    }

    public int getUserSessionCount() {
        return userSessionCount;
    }

    public void setUserSessionCount(int userSessionCount) {
        this.userSessionCount = userSessionCount;
    }

    public void setSessionLength(long sessionLength) {
        this.sessionLength = sessionLength;
    }

    public long getSessionLength() {
        return sessionLength;
    }

    public static String generateSessionID() {
        long unixTime = System.currentTimeMillis() / 1000L;
        return "t" + unixTime + "-" + UUID.randomUUID().toString();
    }

    public String toString() {
        return "SessionId: " + sessionId + "\ncreatedDate: " + createdDate + "\nsessionLength: " + sessionLength + "\nlastSessionDate: " + lastSessionDate + "\nuserSessionCount: " + userSessionCount;
    }

}
