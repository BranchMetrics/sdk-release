package com.tune.ma.analytics.model;

import org.json.JSONArray;

/**
 * Created by johng on 1/11/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public interface TuneAnalyticsListener {
    void dispatchingRequest(JSONArray events);
    void didCompleteRequest(int responseCode);
}
