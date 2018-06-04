package com.tune.ma.deepactions.model;

import com.tune.ma.model.TuneDeepActionCallback;
import com.tune.ma.utils.TuneJsonUtils;

import org.json.JSONObject;

import java.util.List;
import java.util.Map;

/**
 * Created by willb on 1/28/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TuneDeepAction {

    // Event JSON keys
    private static final String NAME = "name";
    private static final String FRIENDLY_NAME = "friendly_name";
    private static final String DESCRIPTION = "description";
    private static final String APPROVED_VALUES = "approved_values";
    private static final String DEFAULT_DATA = "default_data";

    private String actionId;
    private String friendlyName;
    private String description;
    private Map<String, String> defaultData;
    private Map<String, List<String>> approvedValues;
    private TuneDeepActionCallback action;

    public TuneDeepAction(String actionId, String friendlyName, Map<String, String> defaultData, TuneDeepActionCallback action) {
        this(actionId, friendlyName, null, defaultData, null, action);
    }

    public TuneDeepAction(String actionId, String friendlyName, String description, Map<String, String> defaultData, Map<String, List<String>> approvedValues, TuneDeepActionCallback action) {
        this.actionId = actionId;
        this.friendlyName = friendlyName;
        this.description = description;
        this.defaultData = defaultData;
        this.approvedValues = approvedValues;
        this.action = action;
    }

    public String getActionId() {
        return actionId;
    }

    public void setActionId(String actionId) {
        this.actionId = actionId;
    }

    public String getFriendlyName() {
        return friendlyName;
    }

    public void setFriendlyName(String friendlyName) {
        this.friendlyName = friendlyName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Map<String, String> getDefaultData() {
        return defaultData;
    }

    public void setDefaultData(Map<String, String> defaultData) {
        this.defaultData = defaultData;
    }

    public Map<String, List<String>> getApprovedValues() {
        return approvedValues;
    }

    public void setApprovedValues(Map<String, List<String>> approvedValues) {
        this.approvedValues = approvedValues;
    }

    public TuneDeepActionCallback getAction() {
        return action;
    }

    public void setAction(TuneDeepActionCallback action) {
        this.action = action;
    }

    public JSONObject toJson() {
        JSONObject object = new JSONObject();
        TuneJsonUtils.put(object, NAME, actionId);
        TuneJsonUtils.put(object, FRIENDLY_NAME, friendlyName);
        TuneJsonUtils.put(object, DESCRIPTION, description);
        TuneJsonUtils.put(object, APPROVED_VALUES, this.approvedValues);
        TuneJsonUtils.put(object, DEFAULT_DATA, this.defaultData);
        return object;
    }
}
