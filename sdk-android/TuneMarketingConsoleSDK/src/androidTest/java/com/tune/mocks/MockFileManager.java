package com.tune.mocks;

import com.tune.ma.analytics.model.event.TuneAnalyticsEventBase;
import com.tune.ma.file.FileManager;

import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Created by gowie on 2/2/16.
 */
public class MockFileManager implements FileManager {

    private JSONObject configurationResult;
    private JSONObject playlistResult;
    private JSONArray analyticsResult;

    private int writeAnalyticsCount = 0;

    @Override
    public void writeConfiguration(JSONObject configuration) {

    }

    @Override
    public JSONObject readConfiguration() {
        return configurationResult;
    }

    @Override
    public void deleteConfiguration() {

    }

    @Override
    public JSONObject readPlaylist() {
        return playlistResult;
    }

    @Override
    public void writePlaylist(JSONObject playlist) {
        playlistResult = playlist;
    }

    @Override
    public void writeAnalytics(TuneAnalyticsEventBase event) {
        writeAnalyticsCount++;
    }

    @Override
    public JSONArray readAnalytics() {
        return analyticsResult;
    }

    @Override
    public void deleteAnalytics() {

    }

    @Override
    public void deleteAnalytics(int numEventsToDelete) {

    }

    public void setPlaylistResult(JSONObject playlistResult) {
        this.playlistResult = playlistResult;
    }

    public int getAnalyticsCount() {
        return writeAnalyticsCount;
    }
}
