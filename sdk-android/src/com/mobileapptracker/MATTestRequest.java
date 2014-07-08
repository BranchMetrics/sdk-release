package com.mobileapptracker;

import org.json.JSONObject;

public interface MATTestRequest {
    public abstract void constructedRequest(String url, String data, JSONObject postBody);
}
