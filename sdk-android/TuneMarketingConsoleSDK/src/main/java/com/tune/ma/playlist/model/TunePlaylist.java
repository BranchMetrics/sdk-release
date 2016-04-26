package com.tune.ma.playlist.model;

import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by gowie on 1/28/16.
 */
public class TunePlaylist {

    // JSON Keys
    public static final String SCHEMA_VERSION_KEY = "schema_version";
    public static final String POWER_HOOKS_KEY = "power_hooks";
    public static final String IN_APP_MESSAGES_KEY = "messages";
    public static final String EXPERIMENT_DETAILS_KEY = "experiment_details";

    private String schemaVersion;
    private JSONObject powerHooks;
    private JSONObject inAppMessages;
    private JSONObject experimentDetails;
    private boolean fromDisk;

    public TunePlaylist(JSONObject playlistJson) {
        this.schemaVersion = TuneJsonUtils.getString(playlistJson, SCHEMA_VERSION_KEY);
        this.experimentDetails = TuneJsonUtils.getJSONObject(playlistJson, EXPERIMENT_DETAILS_KEY);
        this.powerHooks = TuneJsonUtils.getJSONObject(playlistJson, POWER_HOOKS_KEY);
        this.inAppMessages = TuneJsonUtils.getJSONObject(playlistJson, IN_APP_MESSAGES_KEY);
    }

    public TunePlaylist() {

    }

    public String getSchemaVersion() {
        return schemaVersion;
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

    public boolean isFromDisk() {
        return fromDisk;
    }

    public void setFromDisk(boolean fromDisk) {
        this.fromDisk = fromDisk;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof TunePlaylist)) return false;

        TunePlaylist that = (TunePlaylist) o;

        if (schemaVersion != null ? !schemaVersion.equals(that.schemaVersion) : that.schemaVersion != null) return false;
        if (powerHooks != null ? !powerHooks.equals(that.powerHooks) : that.powerHooks != null) return false;
        if (inAppMessages != null ? !inAppMessages.equals(that.inAppMessages) : that.inAppMessages != null) return false;
        return !(experimentDetails != null ? !experimentDetails.equals(that.experimentDetails) : that.experimentDetails != null);

    }

    @Override
    public int hashCode() {
        int result = schemaVersion != null ? schemaVersion.hashCode() : 0;
        result = 31 * result + (powerHooks != null ? powerHooks.hashCode() : 0);
        result = 31 * result + (inAppMessages != null ? inAppMessages.hashCode() : 0);
        result = 31 * result + (experimentDetails != null ? experimentDetails.hashCode() : 0);
        return result;
    }

    public JSONObject toJson() {
        JSONObject playlistJson = new JSONObject();
        try {
            playlistJson.put(SCHEMA_VERSION_KEY, schemaVersion);
            playlistJson.put(EXPERIMENT_DETAILS_KEY, experimentDetails);
            playlistJson.put(POWER_HOOKS_KEY, powerHooks);
            playlistJson.put(IN_APP_MESSAGES_KEY, inAppMessages);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return playlistJson;
    }
}
