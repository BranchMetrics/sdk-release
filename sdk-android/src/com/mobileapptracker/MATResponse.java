package com.mobileapptracker;

import org.json.JSONObject;

public interface MATResponse {
    public abstract void didSucceedWithData(JSONObject data);
}
