package com.tune.ma.powerhooks.model;

import com.tune.ma.utils.TuneDateUtils;
import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Date;
import java.util.List;

/**
 * Created by gowie on 1/25/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TunePowerHookValue implements Cloneable {

    // Event JSON keys
    public static final String NAME = "name";
    public static final String DEFAULT_VALUE = "default_value";
    public static final String VALUE = "value";
    public static final String FRIENDLY_NAME = "friendly_name";
    public static final String EXPERIMENT_VALUE = "experiment_value";
    public static final String START_DATE = "start_date";
    public static final String END_DATE = "end_date";
    public static final String VARIATION_ID = "variation_id";
    public static final String EXPERIMENT_ID = "experiment_id";
    public static final String DESCRIPTION = "description";
    public static final String APPROVED_VALUES = "approved_values";

    private String hookId;
    private String defaultValue;
    private String friendlyName;
    private String experimentValue;
    private String value;
    private Date startDate;
    private Date endDate;
    private String variationId;
    private String experimentId;
    private String description;
    private List<String> approvedValues;

    public TunePowerHookValue() {}

    public TunePowerHookValue(String hookId, String friendlyName, String defaultValue, String description, List<String> approvedValues) {
        this.hookId = hookId;
        this.defaultValue = defaultValue;
        this.friendlyName = friendlyName;
        this.description = description;
        this.approvedValues = approvedValues;
    }

    public TunePowerHookValue(String hookId, String friendlyName, String defaultValue, String experimentValue, String value, String startDate, String endDate,
                              String variationId, String experimentId, String description, List<String> approvedValues) {
        this.hookId = hookId;
        this.defaultValue = defaultValue;
        this.friendlyName = friendlyName;
        this.experimentValue = experimentValue;
        this.value = value;
        this.variationId = variationId;
        this.experimentId = experimentId;
        this.description = description;
        this.approvedValues = approvedValues;

        this.setStartDate(startDate);
        this.setEndDate(endDate);
    }

    public String getValue() {
        if (hasExperimentValue() && isExperimentRunning()) {
            return this.experimentValue;
        } else if (this.value != null) {
            return this.value;
        } else {
            return this.defaultValue;
        }
    }

    public boolean hasExperimentValue() {
        return this.experimentValue != null;
    }

    public boolean isExperimentRunning() {
        if (!this.hasExperimentValue()) {
            return false;
        } else if (this.startDate == null || this.endDate == null) {
            return false;
        } else {
            return TuneDateUtils.doesNowFallBetweenDates(this.startDate, this.endDate);
        }
    }

    public void mergeWithPlaylistJson(JSONObject json) {
        this.setValue(TuneJsonUtils.getString(json, VALUE));
        this.setExperimentValue(TuneJsonUtils.getString(json, EXPERIMENT_VALUE));
        this.setStartDate(TuneJsonUtils.getString(json, START_DATE));
        this.setEndDate(TuneJsonUtils.getString(json, END_DATE));
        this.setVariationId(TuneJsonUtils.getString(json, VARIATION_ID));
        this.setExperimentId(TuneJsonUtils.getString(json, EXPERIMENT_ID));
    }

    public void setValue(String value) {
        this.value = value;
    }

    public String getDefaultValue() {
        return defaultValue;
    }

    public void setDefaultValue(String defaultValue) {
        this.defaultValue = defaultValue;
    }

    public String getFriendlyName() {
        return friendlyName;
    }

    public void setFriendlyName(String friendlyName) {
        this.friendlyName = friendlyName;
    }

    public String getExperimentValue() {
        return experimentValue;
    }

    public void setExperimentValue(String experimentValue) {
        this.experimentValue = experimentValue;
    }

    public String getHookId() {
        return hookId;
    }

    public void setHookId(String hookId) {
        this.hookId = hookId;
    }

    public Date getStartDate() {
        return startDate;
    }

    public void setStartDate(String startDate) {
        this.startDate = TuneDateUtils.parseIso8601(startDate);
    }

    public Date getEndDate() {
        return endDate;
    }

    public void setEndDate(String endDate) {
        this.endDate = TuneDateUtils.parseIso8601(endDate);
    }

    public String getVariationId() {
        return variationId;
    }

    public void setVariationId(String variationId) {
        this.variationId = variationId;
    }

    public String getExperimentId() {
        return experimentId;
    }

    public void setExperimentId(String experimentId) {
        this.experimentId = experimentId;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public List<String> getApprovedValues() {
        return approvedValues;
    }

    public void setApprovedValues(List<String> approvedValues) {
        this.approvedValues = approvedValues;
    }

    @Override
    public TunePowerHookValue clone() throws CloneNotSupportedException {
        return (TunePowerHookValue) super.clone();
    }

    public JSONObject toJson() {
        JSONObject object = new JSONObject();
        TuneJsonUtils.put(object, NAME, this.hookId);
        TuneJsonUtils.put(object, DEFAULT_VALUE, this.defaultValue);
        TuneJsonUtils.put(object, VALUE, this.value);
        TuneJsonUtils.put(object, FRIENDLY_NAME, this.friendlyName);
        TuneJsonUtils.put(object, EXPERIMENT_VALUE, this.experimentValue);
        TuneJsonUtils.put(object, EXPERIMENT_ID, this.experimentId);
        TuneJsonUtils.put(object, START_DATE, this.startDate);
        TuneJsonUtils.put(object, END_DATE, this.endDate);
        TuneJsonUtils.put(object, VARIATION_ID, this.variationId);
        TuneJsonUtils.put(object, APPROVED_VALUES, this.approvedValues);
        TuneJsonUtils.put(object, DESCRIPTION, this.description);
        return object;
    }
}
