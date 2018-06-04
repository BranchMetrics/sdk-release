package com.tune.ma.file;

import com.tune.ma.analytics.model.event.TuneAnalyticsEventBase;

import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Created by gowie on 2/2/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public interface FileManager {

    void writeConfiguration(JSONObject configuration);

    JSONObject readConfiguration();

    void deleteConfiguration();

    JSONObject readPlaylist();

    void writePlaylist(JSONObject playlist);

    void writeAnalytics(TuneAnalyticsEventBase event);

    JSONArray readAnalytics();

    void deleteAnalytics();

    void deleteAnalytics(int numEventsToDelete);
}
