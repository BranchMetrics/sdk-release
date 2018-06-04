package com.tune.ma.playlist.model;

import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by gowie on 1/28/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TunePlaylist {

    // JSON Keys
    public static final String SCHEMA_VERSION_KEY = "schema_version";
    public static final String POWER_HOOKS_KEY = "power_hooks";
    public static final String IN_APP_MESSAGES_KEY = "messages";
    public static final String EXPERIMENT_DETAILS_KEY = "experiment_details";
    public static final String SEGMENTS_KEY = "segments";

    private String schemaVersion;
    private JSONObject powerHooks;
    private JSONObject inAppMessages;
    private JSONObject experimentDetails;
    private JSONObject segments;
    private boolean fromDisk;
    private boolean fromConnectedMode;

    public TunePlaylist(JSONObject playlistJson) {
        this.schemaVersion = TuneJsonUtils.getString(playlistJson, SCHEMA_VERSION_KEY);
        this.experimentDetails = TuneJsonUtils.getJSONObject(playlistJson, EXPERIMENT_DETAILS_KEY);
        this.powerHooks = TuneJsonUtils.getJSONObject(playlistJson, POWER_HOOKS_KEY);
        this.inAppMessages = TuneJsonUtils.getJSONObject(playlistJson, IN_APP_MESSAGES_KEY);
        this.segments = TuneJsonUtils.getJSONObject(playlistJson, SEGMENTS_KEY);
    }

    public TunePlaylist() {
    }

    public void setSchemaVersion(String schemaVersion) {
        this.schemaVersion = schemaVersion;
    }

    public JSONObject getPowerHooks() {
        return powerHooks;
    }

    public void setPowerHooks(JSONObject powerHooks) {
        this.powerHooks = powerHooks;
    }

    public JSONObject getInAppMessages() {
        return inAppMessages;
    }

    public void setInAppMessages(JSONObject inAppMessages) {
        this.inAppMessages = inAppMessages;
    }

    public JSONObject getExperimentDetails() {
        return experimentDetails;
    }

    public void setExperimentDetails(JSONObject experimentDetails) {
        this.experimentDetails = experimentDetails;
    }

    public JSONObject getSegments() {
        return segments;
    }

    public void setSegments(JSONObject segments) {
        this.segments = segments;
    }

    public boolean isFromDisk() {
        return fromDisk;
    }

    public void setFromDisk(boolean fromDisk) {
        this.fromDisk = fromDisk;
    }

    public boolean isFromConnectedMode() {
        return fromConnectedMode;
    }

    public void setFromConnectedMode(boolean fromConnectedMode) {
        this.fromConnectedMode = fromConnectedMode;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof TunePlaylist)) return false;

        TunePlaylist that = (TunePlaylist) o;

        if (schemaVersion != null ? !schemaVersion.equals(that.schemaVersion) : that.schemaVersion != null) return false;
        if (powerHooks != null && that.powerHooks != null ? !powerHooks.toString().equals(that.powerHooks.toString()) : powerHooks != that.powerHooks) return false;
        if (inAppMessages != null && that.inAppMessages != null ? !inAppMessages.toString().equals(that.inAppMessages.toString()) : inAppMessages != that.inAppMessages) return false;
        if (segments != null && that.segments != null ? !segments.toString().equals(that.segments.toString()) : segments != that.segments) return false;
        return !(experimentDetails != null && that.experimentDetails != null ? !experimentDetails.toString().equals(that.experimentDetails.toString()) : experimentDetails != that.experimentDetails);

    }

    @Override
    public int hashCode() {
        int result = schemaVersion != null ? schemaVersion.hashCode() : 0;
        result = 31 * result + (powerHooks != null ? powerHooks.toString().hashCode() : 0);
        result = 31 * result + (inAppMessages != null ? inAppMessages.toString().hashCode() : 0);
        result = 31 * result + (experimentDetails != null ? experimentDetails.toString().hashCode() : 0);
        result = 31 * result * (segments != null ? segments.toString().hashCode() : 0);
        return result;
    }

    public JSONObject toJson() {
        JSONObject playlistJson = new JSONObject();
        try {
            playlistJson.put(SCHEMA_VERSION_KEY, schemaVersion);
            playlistJson.put(EXPERIMENT_DETAILS_KEY, experimentDetails);
            playlistJson.put(POWER_HOOKS_KEY, powerHooks);
            playlistJson.put(IN_APP_MESSAGES_KEY, inAppMessages);
            playlistJson.put(SEGMENTS_KEY, segments);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return playlistJson;
    }
}
