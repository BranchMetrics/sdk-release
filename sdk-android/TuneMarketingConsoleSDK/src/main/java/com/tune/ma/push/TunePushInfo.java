package com.tune.ma.push;

import org.json.JSONObject;

/**
 * Created by charlesgilliam on 6/9/16.
 */
public class TunePushInfo {
    private String campaignId;
    private String pushId;
    private JSONObject extrasPayload;

    /**
     * @return The campaignId for the message.
     */
    public String getCampaignId() {
        return campaignId;
    }

    /**
     * @return The pushId for the message.
     */
    public String getPushId() {
        return pushId;
    }

    /**
     * Returns the extra information passed in through the payload either from:
     * 1. The "JSON Payload" field in the campaign screen
     * 2. The "extraPushPayload" of the push API
     * Or an empty JSONObject if nothing was passed through.
     */
    public JSONObject getExtrasPayload() {
        return extrasPayload;
    }

    void setCampaignId(String campaignId) {
        this.campaignId = campaignId;
    }

    void setPushId(String pushId) {
        this.pushId = pushId;
    }

    void setExtrasPayload(JSONObject payload) {
        this.extrasPayload = payload;
    }
}
