package com.tune.ma.inapp.model;

import android.text.TextUtils;

import com.tune.ma.utils.TuneDateUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Date;

/**
 * Created by johng on 4/24/17.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneMessageDisplayCount {
    // Keys for JSON serialization
    public static final String CAMPAIGN_ID_KEY = "campaignId";
    public static final String TRIGGER_EVENT_KEY = "triggerEvent";
    public static final String LAST_SHOWN_DATE_KEY = "lastShownDate";
    public static final String LIFETIME_SHOWN_COUNT_KEY = "lifetimeShownCount";
    public static final String EVENTS_SEEN_SINCE_SHOWN_KEY = "eventsSeenSinceShown";
    public static final String NUMBER_OF_TIMES_SHOWN_THIS_SESSION_KEY = "numberOfTimesShownThisSession";

    private String campaignId;
    private String triggerEvent;
    private Date lastShownDate;
    private int lifetimeShownCount;
    private int eventsSeenSinceShown;
    private int numberOfTimesShownThisSession;

    private TuneMessageDisplayCount() {
    }

    public TuneMessageDisplayCount(String campaignId, String triggerEvent) {
        this.campaignId = campaignId;
        this.triggerEvent = triggerEvent;
        this.lifetimeShownCount = 0;
        this.eventsSeenSinceShown = 0;
        this.numberOfTimesShownThisSession = 0;
    }

    public static TuneMessageDisplayCount fromJson(JSONObject json) {
        TuneMessageDisplayCount displayCount = new TuneMessageDisplayCount();
        try {
            displayCount.campaignId = json.getString(CAMPAIGN_ID_KEY);
            displayCount.triggerEvent = json.getString(TRIGGER_EVENT_KEY);
            if (!TextUtils.isEmpty(json.optString(LAST_SHOWN_DATE_KEY))) {
                displayCount.lastShownDate = TuneDateUtils.getDateFromString(json.optString(LAST_SHOWN_DATE_KEY));
            }
            displayCount.lifetimeShownCount = json.getInt(LIFETIME_SHOWN_COUNT_KEY);
            displayCount.eventsSeenSinceShown = json.getInt(EVENTS_SEEN_SINCE_SHOWN_KEY);
            displayCount.numberOfTimesShownThisSession = json.getInt(NUMBER_OF_TIMES_SHOWN_THIS_SESSION_KEY);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return displayCount;
    }

    public JSONObject toJson() {
        JSONObject json = new JSONObject();
        try {
            json.put(CAMPAIGN_ID_KEY, this.campaignId);
            json.put(TRIGGER_EVENT_KEY, this.triggerEvent);
            json.put(LAST_SHOWN_DATE_KEY, this.lastShownDate);
            json.put(LIFETIME_SHOWN_COUNT_KEY, this.lifetimeShownCount);
            json.put(EVENTS_SEEN_SINCE_SHOWN_KEY, this.eventsSeenSinceShown);
            json.put(NUMBER_OF_TIMES_SHOWN_THIS_SESSION_KEY, this.numberOfTimesShownThisSession);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return json;
    }

    public synchronized String getCampaignId() {
        return campaignId;
    }

    public synchronized String getTriggerEvent() {
        return triggerEvent;
    }

    public synchronized Date getLastShownDate() {
        return lastShownDate;
    }

    public synchronized void setLastShownDate(Date lastShownDate) {
        this.lastShownDate = lastShownDate;
    }

    public synchronized int getLifetimeShownCount() {
        return lifetimeShownCount;
    }

    public synchronized void setLifetimeShownCount(int lifetimeShownCount) {
        this.lifetimeShownCount = lifetimeShownCount;
    }

    public synchronized void incrementLifetimeShownCount() {
        this.lifetimeShownCount++;
    }

    public synchronized int getEventsSeenSinceShown() {
        return eventsSeenSinceShown;
    }

    public synchronized void setEventsSeenSinceShown(int eventsSeenSinceShown) {
        this.eventsSeenSinceShown = eventsSeenSinceShown;
    }

    public synchronized void incrementEventsSeenSinceShown() {
        this.eventsSeenSinceShown++;
    }

    public synchronized int getNumberOfTimesShownThisSession() {
        return numberOfTimesShownThisSession;
    }

    public synchronized void setNumberOfTimesShownThisSession(int numberOfTimesShownThisSession) {
        this.numberOfTimesShownThisSession = numberOfTimesShownThisSession;
    }

    public synchronized void incrementNumberOfTimesShownThisSession() {
        this.numberOfTimesShownThisSession++;
    }

    @Override
    public String toString() {
        return "TuneMessageDisplayCount{" +
                "campaignId='" + campaignId + '\'' +
                ", triggerEvent='" + triggerEvent + '\'' +
                ", lastShownDate=" + lastShownDate +
                ", lifetimeShownCount=" + lifetimeShownCount +
                ", eventsSeenSinceShown=" + eventsSeenSinceShown +
                ", numberOfTimesShownThisSession=" + numberOfTimesShownThisSession +
                '}';
    }
}
