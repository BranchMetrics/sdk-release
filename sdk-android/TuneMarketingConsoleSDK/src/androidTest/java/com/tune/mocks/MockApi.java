package com.tune.mocks;

import com.tune.http.Api;
import com.tune.ma.analytics.model.TuneAnalyticsListener;

import org.json.JSONObject;

/**
 * Created by gowie on 2/1/16.
 */
public class MockApi implements Api {

    JSONObject playlistResponse;
    int playlistRequestCount;

    JSONObject configuration;

    boolean postResult = true; // Default to successful Analytics Post
    int analyticsPostCount;
    JSONObject postedEvents;

    int connectedAnalyticsPostCount;
    JSONObject postedConnectedEvent;

    int connectCount;
    int disconnectCount;
    int syncCount;

    public MockApi() {
    }

    // Interface Methods
    /////////////////////

    @Override
    public JSONObject getPlaylist() {
        playlistRequestCount++;
        return playlistResponse;
    }

    @Override
    public JSONObject getConfiguration() {
        return null;
    }

    @Override
    public boolean postAnalytics(JSONObject events, TuneAnalyticsListener listener) {
        postedEvents = events;
        analyticsPostCount++;
        return postResult;
    }

    @Override
    public boolean postConnectedAnalytics(JSONObject event, TuneAnalyticsListener listener) {
        postedConnectedEvent = event;
        connectedAnalyticsPostCount++;
        return postResult;
    }

    @Override
    public boolean postConnect() {
        connectCount++;
        return postResult;
    }

    @Override
    public boolean postDisconnect() {
        disconnectCount++;
        return postResult;
    }

    @Override
    public boolean postSync(JSONObject syncObject) {
        syncCount++;
        return postResult;
    }

    @Override
    public JSONObject getConnectedPlaylist() {
        playlistRequestCount++;
        return playlistResponse;
    }

    // Mock Methods
    ////////////////


    public int getPlaylistRequestCount() {
        return playlistRequestCount;
    }

    public int getAnalyticsPostCount() {
        return analyticsPostCount;
    }

    public int getConnectedAnalyticsPostCount() {
        return connectedAnalyticsPostCount;
    }

    public int getConnectCount() {
        return connectCount;
    }

    public int getDisconnectCount() {
        return disconnectCount;
    }

    public int getSyncCount() {
        return syncCount;
    }

    public JSONObject getPostedEvents() {
        return postedEvents;
    }

    public JSONObject getPostedConnectedEvent() {
        return postedConnectedEvent;
    }

    public void setPlaylistResponse(JSONObject playlistResponse) {
        this.playlistResponse = playlistResponse;
    }

    public void setConfiguration(JSONObject configuration) {
        this.configuration = configuration;
    }

    public void setPostResult(boolean postResult) {
        this.postResult = postResult;
    }
}
