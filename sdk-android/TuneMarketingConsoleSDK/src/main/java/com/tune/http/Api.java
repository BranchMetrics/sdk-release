package com.tune.http;

import com.tune.ma.analytics.model.TuneAnalyticsListener;

import org.json.JSONObject;

/**
 * Created by gowie on 2/1/16.
 */
public interface Api {

    JSONObject getPlaylist();

    JSONObject getConfiguration();

    boolean postAnalytics(JSONObject events, TuneAnalyticsListener listener);

    boolean postConnectedAnalytics(JSONObject event, TuneAnalyticsListener listener);

    boolean postConnect();

    boolean postDisconnect();

    boolean postSync(JSONObject syncObject);

    JSONObject getConnectedPlaylist();
}
