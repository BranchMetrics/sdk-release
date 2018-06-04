package com.tune.ma.push.model;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

/**
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
public class TunePushOpenAction {
    private static final String JSON_AUTO_CANCEL = "D";
    private static final String JSON_CAMPAIGN_STEP_ID = "CS";
    private static final String JSON_DEEP_LINK = "URL";
    private static final String JSON_DEEP_ACTION_ID = "DA";
    private static final String JSON_DEEP_ACTION_PARAMS = "DAD";

    private String autoCancelFlag;
    private String campaignStepId;
    private String deepActionId;
    private Map<String, String> deepActionParameters;
    private String deepLinkURL;

    public TunePushOpenAction(JSONObject object) throws JSONException {
        if (object.has(JSON_AUTO_CANCEL)) {
            autoCancelFlag = object.getString(JSON_AUTO_CANCEL);
        }
        if (object.has(JSON_CAMPAIGN_STEP_ID)) {
            campaignStepId = object.getString(JSON_CAMPAIGN_STEP_ID);
        }

        boolean hasDeepLink = object.has(JSON_DEEP_LINK);
        boolean hasDeepAction = object.has(JSON_DEEP_ACTION_ID);
        if (hasDeepLink && hasDeepAction) {
            throw new JSONException("Push action was not formatted correctly: " + object.toString());
        } else if (hasDeepLink) {
            deepLinkURL = object.getString(JSON_DEEP_LINK);
        } else if (hasDeepAction) {
            deepActionId = object.getString(JSON_DEEP_ACTION_ID);

            if (object.has(JSON_DEEP_ACTION_PARAMS)) {
                deepActionParameters = new HashMap<String, String>();
                JSONObject p = object.getJSONObject(JSON_DEEP_ACTION_PARAMS);
                Iterator<?> keys = p.keys();
                while (keys.hasNext()) {
                    String key = (String) keys.next();
                    deepActionParameters.put(key, p.getString(key));
                }
            }
        }
    }

    public String getDeepActionId() {
        return deepActionId;
    }

    public Map<String, String> getDeepActionParameters() {
        return deepActionParameters;
    }

    public String getDeepLinkURL() {
        return deepLinkURL;
    }

    public boolean isAutoCancelNotification() {
        // if the flag isn't set we default to autoCancel.
        return autoCancelFlag == null || "1".equals(autoCancelFlag);
    }

    public JSONObject toJson() {
        JSONObject object = new JSONObject();
        try {
            object.put(JSON_AUTO_CANCEL, autoCancelFlag);
            object.put(JSON_CAMPAIGN_STEP_ID, campaignStepId);

            object.put(JSON_DEEP_ACTION_ID, deepActionId);
            if (deepActionParameters != null && deepActionParameters.size() > 0) {
                JSONObject deepActionParams = new JSONObject();
                for (Map.Entry<String, String> e : deepActionParameters.entrySet()) {
                    deepActionParams.put(e.getKey(), e.getValue());
                }
                object.put(JSON_DEEP_ACTION_PARAMS, deepActionParams);
            }

            object.put(JSON_DEEP_LINK, deepLinkURL);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return object;
    }
}
