package com.tune;

import org.json.JSONObject;

public interface TuneTestRequest {
    public abstract void constructedRequest(String url, String data, JSONObject postBody);
}
