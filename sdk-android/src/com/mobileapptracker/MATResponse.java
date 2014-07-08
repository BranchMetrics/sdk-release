package com.mobileapptracker;

import org.json.JSONObject;

public interface MATResponse {
    public abstract void enqueuedActionWithRefId(String refId);
    
    public abstract void didSucceedWithData(JSONObject data);
    
    public abstract void didFailWithError(JSONObject error);
}
