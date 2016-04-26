package com.tune.ma.analytics.model;

import org.json.JSONArray;

/**
 * Created by johng on 1/11/16.
 */
public interface TuneAnalyticsListener {
    void dispatchingRequest(JSONArray events);
    void didCompleteRequest(int responseCode);
}
