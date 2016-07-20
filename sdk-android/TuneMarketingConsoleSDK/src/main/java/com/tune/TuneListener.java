package com.tune;

import org.json.JSONObject;

public interface TuneListener {
    public abstract void enqueuedActionWithRefId(String refId);

    public abstract void enqueuedRequest(String url, JSONObject postData);
    
    public abstract void didSucceedWithData(JSONObject data);
    
    public abstract void didFailWithError(JSONObject error);
}
