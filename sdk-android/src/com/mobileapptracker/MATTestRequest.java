package com.mobileapptracker;

import org.json.JSONObject;

public interface MATTestRequest {
	public abstract void paramsToBeEncrypted( String params );
    public abstract void constructedRequest(String url, JSONObject data);
}
